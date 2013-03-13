package info.peterlane.svmdemo;

import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.Dimension;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.GridLayout;
import java.awt.Image;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.MouseEvent;
import java.awt.event.MouseListener;
import java.util.ArrayList;
import java.util.List;
import javax.swing.JButton;
import javax.swing.JComboBox;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JSpinner;
import javax.swing.JTextField;
import javax.swing.SpinnerNumberModel;
import javax.swing.SwingWorker;
import javax.swing.border.TitledBorder;

import static libsvm.Svm.svm_predict;
import static libsvm.Svm.svm_train;
import libsvm.Model;
import libsvm.Node;
import libsvm.Parameter;
import libsvm.Problem;

public class Demo1 extends JFrame {

  /** Get the interface started in its own GUI thread */
  public static void main (String[] args) {
    javax.swing.SwingUtilities.invokeLater(new Runnable() {
      public void run() { new Demo1 (); }
    });
  }

  public Demo1 () {
    super ("Support-Vector Machines: Demonstration");
    setSize (700, 400);
    setDefaultCloseOperation(DISPOSE_ON_CLOSE);

    setLayout (new BorderLayout ());
    
    display = new Display ();
    message = new JLabel ();

    add (new JScrollPane (display));
    add (labelButtons (), BorderLayout.NORTH);
    add (trainButtons (), BorderLayout.EAST);
    add (helpLine (), BorderLayout.SOUTH);

    setVisible (true);
  }

  private JPanel labelButtons () {
    JPanel panel = new JPanel ();
    panel.setLayout (new BorderLayout ());

    JComboBox<String> box = new JComboBox<String> (
        new String[]{"blue", "green"}
        );
    box.addActionListener (new LabelListener (display, box));

    JButton clearButton = new JButton ("Clear");
    clearButton.addActionListener (new ActionListener () {
      public void actionPerformed (ActionEvent e) {
        display.clear ();
      }
    });

    JPanel pane = new JPanel ();
    pane.add (new JLabel ("Class:"));
    pane.add (box);
    pane.add (clearButton);

    panel.add (pane, BorderLayout.WEST);
    panel.add (message);

    return panel;
  }

  private JPanel trainButtons () {
    final JComboBox<String> kernelChoice = new JComboBox<> (
        new String[]{"linear", "RBF", "polynomial", "sigmoid"}
        );

    final JTextField costChoice = new JTextField (10);
    costChoice.setText ("1.0");
    costChoice.setMaximumSize (costChoice.getPreferredSize ());

    final JTextField gammaChoice = new JTextField (10);
    gammaChoice.setText ("1.0");
    gammaChoice.setMaximumSize (gammaChoice.getPreferredSize ());
    gammaChoice.setEnabled (false);

    final JSpinner degreeChoice = new JSpinner (new SpinnerNumberModel(1, 0, 30, 1));
    degreeChoice.setEnabled (false);

    kernelChoice.addActionListener (new KernelChoiceListener (kernelChoice, gammaChoice, degreeChoice));

    final JButton run = new JButton ("Train");
    this.getRootPane().setDefaultButton (run);

    run.addActionListener (new ActionListener () {
      public void actionPerformed (ActionEvent e) {
        // select kernel
        final int kernel;
        switch ((String)(kernelChoice.getSelectedItem ())) {
          case "linear": kernel = Parameter.LINEAR; break;
          case "RBF": kernel = Parameter.RBF; break;
          case "polynomial": kernel = Parameter.POLY; break;
          //case "sigmoid": 
          default: kernel = Parameter.SIGMOID; break;
        };
        // find cost
        final double cost;
        try {
          cost = new Double (costChoice.getText ());
        } catch (NumberFormatException nfe) {
          JOptionPane.showMessageDialog (null,
            "Cost Value " + costChoice.getText () + " is not a number",
            "Error in cost value",
            JOptionPane.ERROR_MESSAGE);
          return;
        }
        // find gamma
        final double gamma;
        try {
          gamma = new Double (gammaChoice.getText ());
        } catch (NumberFormatException nfe) {
          JOptionPane.showMessageDialog (null,
            "Gamma Value " + gammaChoice.getText () + " is not a number",
            "Error in gamma value",
            JOptionPane.ERROR_MESSAGE);
          return;
        }
        // find degree
        final int degree = ((SpinnerNumberModel)(degreeChoice.getModel())).getNumber().intValue ();
        // do training
        message.setText ("Training and updating display: Please wait");
        // set off training in SwingWorker thread
        SwingWorker<Void, Void> worker = new SwingWorker<Void, Void> () {
          @Override
          public Void doInBackground () {
            run.setEnabled (false);
            display.train (kernel, cost, gamma, degree);
            message.setText ("");
            return null;
          }

          @Override
          public void done () {
            run.setEnabled (true);
          };
        };
        worker.execute ();
      }
    });


    JPanel panel = new JPanel ();
    panel.setBorder (new TitledBorder ("Training options"));
    panel.setLayout (new GridLayout (5, 2, 10, 10));

    panel.add (new JLabel ("Kernel type:", JLabel.RIGHT));
    panel.add (kernelChoice);
    panel.add (new JLabel ("Cost:", JLabel.RIGHT));
    panel.add (costChoice);
    panel.add (new JLabel ("Gamma:", JLabel.RIGHT));
    panel.add (gammaChoice);
    panel.add (new JLabel ("Degree:", JLabel.RIGHT));
    panel.add (degreeChoice);
    panel.add (new JLabel (""));
    panel.add (run);

    JPanel pane = new JPanel ();
    pane.add (panel);
    return pane;
  }

  private JLabel helpLine () {
    return new JLabel ("<html><body>Select a class colour and click on main panel to define instances.<br>Choose kernel type and parameter settings for training.</body></html>");
  }

  private final Display display;
  private final JLabel message;

  class KernelChoiceListener implements ActionListener {
    KernelChoiceListener (JComboBox<String> kernelChoice, JTextField gammaChoice, JSpinner degreeChoice) {
      this.kernelChoice = kernelChoice;
      this.gammaChoice = gammaChoice;
      this.degreeChoice = degreeChoice;
    }

    public void actionPerformed (ActionEvent e) {
      switch ((String)(kernelChoice.getSelectedItem ())) {
        case "linear":
          gammaChoice.setEnabled (false);
          degreeChoice.setEnabled (false);
          break;
        case "polynomial":
          gammaChoice.setEnabled (false);
          degreeChoice.setEnabled (true);
          break;
        case "RBF": case "sigmoid":
          gammaChoice.setEnabled (true);
          degreeChoice.setEnabled (false);
          break;
      };
    }

    private final JComboBox<String> kernelChoice;
    private final JTextField gammaChoice;
    private final JSpinner degreeChoice;
  }

  class LabelListener implements ActionListener {
    LabelListener (Display display, JComboBox box) {
      this.display = display;
      this.box = box;
    }

    public void actionPerformed (ActionEvent e) {
      if (((String)(box.getSelectedItem())).equals ("blue")) {
        display.setColour (Color.BLUE);
      } else {
        display.setColour (Color.GREEN);
      }
    }

    private final Display display;
    private final JComboBox box;
  }
}

class Display extends JPanel {

  Display () {
    super ();

    setPreferredSize (new Dimension (width, height));
    addMouseListener (new MyMouseListener (this));

    points = new ArrayList<Point> ();
    supportVectors = new ArrayList<Point> ();
    colour = Color.BLUE;
  }

  public void paint (Graphics g) {
    super.paint (g);

    Graphics2D g2 = (Graphics2D)g;

    if (buffer == null) {
      g2.setBackground (Color.LIGHT_GRAY);
      g2.clearRect (0, 0, width, height);
    } else {
      g2.drawImage (buffer, 0, 0, this);
    }

    for (Point point : supportVectors) {
      g2.setColor (Color.YELLOW);
      g2.fillOval (point.x - 7, point.y - 7, 14, 14);
    }

    for (Point point : points) {
      g2.setColor (point.colour);
      g2.fillOval (point.x - 3, point.y - 3, 6, 6);
    }
  }

  public void clear () {
    points.clear ();
    supportVectors.clear ();
    buffer = null;
    repaint ();
  }
  
  public void setColour (Color colour) {
    this.colour = colour;
  }

  void clicked (int x, int y) {
    if (x < width && y < height) {
      points.add (new Point (x, y, colour));
      repaint ();
    }
  }

  Color backgroundColour (double prediction) {
    if (prediction == 0.0) {
      return new Color (100, 200, 100);
    } else {
      return new Color (100, 100, 200);
    }
  }

  public void train (int kernel, double cost, double gamma, int degree) {
    if (points.isEmpty ()) return;

    Problem problem = new Problem ();
    problem.l = points.size ();
    problem.y = new double[problem.l];
    problem.x = new Node[problem.l][2];
    int index = 0;
    for (Point point : points) {
      if (point.colour == Color.BLUE) {
        problem.y[index] = 1;
      } else {
        problem.y[index] = 0;
      }
      Node node_0 = new Node ();
      node_0.index = 0;
      node_0.value = (double)(point.x) / width;
      problem.x[index][0] = node_0;
      Node node_1 = new Node ();
      node_1.index = 1;
      node_1.value = (double)(point.y) / height;
      problem.x[index][1] = node_1;
      index += 1;
    }
    Parameter parameter = new Parameter ();
    parameter.svm_type = Parameter.C_SVC;
    parameter.kernel_type = kernel;
    parameter.C = cost;
    parameter.gamma = gamma;
    parameter.degree = degree;
    parameter.coef0 = 0.0;
    parameter.eps = 0.001;
    parameter.nr_weight = 0;
    parameter.nu = 0.5;
    parameter.p = 0.1;
    parameter.shrinking = 1;
    parameter.probability = 0;

    Model model = svm_train (problem, parameter);

    // redraw
    Image buffer = createImage (width, height);
    Graphics bufferg = buffer.getGraphics ();
    Graphics windowg = this.getGraphics ();
    Node[] instance = new Node[2];
    instance[0] = new Node ();
    instance[0].index = 0;
    instance[1] = new Node ();
    instance[1].index = 1;

    for (int i = 0; i < width; i += 1) {
      if (i < 498) { // draw a progress line
        bufferg.setColor (Color.RED);
        bufferg.drawLine (i+1, 0, i+1, height-1);
        windowg.setColor (Color.RED);
        windowg.drawLine (i+1, 0, i+1, height-1);
      }
      for (int j = 0; j < height; j += 1) {
        instance[0].value = (double)i / width;
        instance[1].value = (double)j / height;
        double prediction = svm_predict(model, instance);
        bufferg.setColor (backgroundColour (prediction));
        bufferg.drawLine (i, j, i, j);
        windowg.setColor (backgroundColour (prediction));
        windowg.drawLine (i, j, i, j);
      }
    }

    this.buffer = buffer;
    supportVectors.clear ();
    for (int i : model.sv_indices) {
      supportVectors.add (points.get (i));
    }

    repaint ();
  }

  private List<Point> points;
  private List<Point> supportVectors;
  private Color colour;
  private Image buffer;
  private final int width = 800;
  private final int height = 600;

  class MyMouseListener implements MouseListener {
    MyMouseListener (Display parent) {
      this.parent = parent;
    }

    public void mouseEntered (MouseEvent e) {
    }
    public void mouseExited (MouseEvent e) {
    }
    public void mousePressed (MouseEvent e) {
    }
    public void mouseReleased (MouseEvent e) {
    }
    public void mouseClicked (MouseEvent e) {
      parent.clicked (e.getX (), e.getY ());
    }

    private final Display parent;
  }

  class Point {
    int x;
    int y;
    Color colour;

    Point (int x, int y, Color colour) {
      this.x = x;
      this.y = y;
      this.colour = colour;
    }
  }
}
