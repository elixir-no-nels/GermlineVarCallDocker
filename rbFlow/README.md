# rb-flow

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

```
gem 'rbFlow'

```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rbFlow
    
## Description

rbFlow is a small and simple workflow engine based on Rake, a software task management using Ruby langage.
rbFlow use a yaml file that discribe your workflow to create Rake scripts using Rake task templates.
The workflow can be run on the fly on independently from rbFlow as a simple Rake scripts workflow.

- Ruby and Rake : https://www.ruby-lang.org/en/
- Rake : http://en.wikipedia.org/wiki/Rake_%28software%29
- Yaml : http://yaml.org/

## Usage

```
../bin/rbFlow.rb -h


Loading Template Rake Task Modules
-------------------------------------------------------------
DefaultTask              	from	../system_modules/default_task.rb
DefaultTaskStandAlone    	from	../system_modules/default_task_standalone.rb
Test                     	from	../tool_modules/test.rb
VarScan2                 	from	../tool_modules/varscan2.rb
-------------------------------------------------------------


Usage :
-c    --conf FILE.conf Load yaml conf file that discribe the workflow. Value: config.yaml
-r    --run            Run the workflow now.                           Value: false
-d    --debug          Show debug messages                             Value: false


```

### Setup your environment


Create a directory to run your workflow with your input data and the configuration file of your workflow

```
-WorkFlow_XXX----|
                 |-inputs_dir-----|
                 |                |-some_inputs_file_01
                 |                |-some_inputs_file_02
                 |                |-some_inputs_file_03
                 |
                 |-configure.yaml

```


### Run a workflow

Just generate the Workflow rake scripts from a configuration file named config.yaml

```
rbFlow.rb

```

Generate the Workflow rake script from a configuration file named config.yaml and run it

```
rbFlow.rb -r

```

Generate the Workflow rake script from a configuration file named custom_name.yaml and run it

```
rbFlow.rb -c custom_name.yaml -r

```

Run or rerun a Workflow previously generated

```
rake -f workflow_name_default.rb

```


#### Run a complete Workflow

#### Rerun a workflow

Run or rerun a Workflow previously generated

```
rake -f workflow_name_default.rb

```

A specific step of the workflow

```
rake -f workflow_name_default.rb step_name

```


#### Get information about the workflow

All rake commands need a generated rake workflow.

Get the list of all task in your Workflow 

```
rake -T -f workflow_name_default.rb
# or
rake -D -f workflow_name_default.rb

```

Get a dependency overwiew between tasks 

```
rake -P -f workflow_name_default.rb

```
### Write a workflow

The workflow descrition is a text file using the yaml format.




### Write a module

Each step of the workflow use a tool module writed in Ruby, using the erb template system (Embended RuBy).

#### get_config_template


#### tool_template


#### step_validation_template



## TODO

### Convert from rbFlow version alpha

- ADTex.rb
- b_allele_frequency.rb
- gatk_AnalyzeCovariates.rb
- gatk_ApplyRecalibration.rb
- gatk_PrintReads.rb
- gatk_UnifiedGenotyper.rb
- gatk_VariantFiltration.rb
- gatk_VariantRecalibrator.rb


### Files manipulation

- files_move
- files_copy
- files_link
- files_rm


### Optional TODO

- gpg2_encrypt
- demultiplex


## Contributing

1. Fork it ( https://github.com/[my-github-username]/rbFlow/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
