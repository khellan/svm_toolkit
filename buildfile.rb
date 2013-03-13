define 'svm-demo' do
  project.version = '1.0'

  package(:jar).with(
    :manifest => { 'Main-Class' => 'info.peterlane.svmdemo.Demo1' }
  )

  run.using :main => "info.peterlane.svmdemo.Demo1"
end
