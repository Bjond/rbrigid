![alt text](https://github.com/Bjond/rbrigid/blob/master/images/bjondhealthlogo-whitegrey.png "Bjönd Inc.")

#*BRIGID*

_Brigid is the Celtic god of knowledge and wisdom_

Accepts an audit log in stdin and emits an un-opaqued version to stdout.

This scripts requires access to a postgreSQL database. You will need to install libpg-dev
onto your linux system. libpg-dev is the C library interface to postgreSQL.

```shell
$ sudo apt-get install libpq-dev
```

Then you will require the GEM to interface with this shared library:

```shell
$ sudo gem install pg
```

Should be that simple. 


Usage: 

```ruby
brigid = Brigid.new
brigid.read_audit_log('secure-audit.log', 'outfile.log')
brigid.close
```

The outfile.log will contain the unobfuscated data. It is possible to print the version of the current pg library
used for debuging:

```ruby
brigid = Brigid.new
puts brigid.version_of_libprg
brigid.read_audit_log('secure-audit.log', 'outfile.log')
brigid.close
```

You may also run individual searches which might be convenient:

```ruby
brigid = Brigid.new
puts brigid.version_of_libprg
puts brigid.find_tag_name_by_id('0c51e93c-3a1f-11e5-b6bd-129ad806adaf')
puts brigid.find_tag_name_by_id('0c51e93c-3a1f-11e5-b6bd-129ad806ada').nil?

puts brigid.find_question_name_by_id('c57c26f8-3a0a-11e5-b6bd-129ad806adaf')
puts brigid.find_rule_definition_name_by_id('d894491d-986a-11e5-ae77-0eb49f101791')
puts brigid.find_person_name_by_id('07a82c50-5598-11e5-aa66-129ad806adaf')
puts brigid.find_person_name_by_id('07a82c50-5598-11e5-aa66-129ad806ad').nil?
puts brigid.find_user_defined_role_name_by_id('4c2d9c38-7ccf-11e5-98a5-0ebd4f99f70f')
puts brigid.find_bjond_task_by_id('246c7a0c-5007-11e5-aa5b-129ad806adaf')
puts brigid.find_assessment_name_by_id('3851a431-61fe-11e5-8cea-129ad806adaf')
puts brigid.find_role_name_by_id('07c6790c-3277-466d-a448-9060d54531ae')
puts brigid.find_group_name_by_id('4b6c668c-1e57-475d-8ae1-ee1e910d71c9')
puts brigid.find_user_by_id('012afd5b-30f8-4a2d-80dc-ec68cdfc4eac')

brigid.close
```





