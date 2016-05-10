#!/usr/local/bin/ruby -w
# _*_ coding: utf-8 _*_

#
#  Class: Brigid
#
#  Description:  Reads an obfuscated secure-audit.log file and outputs stdout a
#  un-obfuscated log. See http://zetcode.com/db/postgresqlruby/ for instructions
#  on installing the libpg library on linux.
#
#  The short version is here:
#  sudo apt-get install libpq-dev # install postgresql development shared lib
#
#  sudo gem install pg  # install GEM interface to libpg
#
#  See the README for usage.
#
#  Copyright (c) 2016
#  by Bjönd Health, Inc., Boston, MA
#
#  This software is furnished under a license and may be used only in
#  accordance with the terms of such license.  This software may not be
#  provided or otherwise made available to any other party.  No title to
#  nor ownership of the software is hereby transferred.
#
#  This software is the intellectual property of Bjönd Health, Inc.,
#  and is protected by the copyright laws of the United States of America.
#  All rights reserved internationally.
#
#  @version 0.001 05/05/16
#  @author Stephen Agneta
#  @since Build 1.000
#
require 'pg'
require 'csv'

# Brigid class. Main entry point to this application
class Brigid
  def initialize(host, port, dbname, user, password)
    @con = PG.connect host: host, port: port, dbname: dbname, user: user, password: password
    @con.prepare 'findTagNameByID', 'SELECT p.name FROM tags_fulltext p WHERE p.id =$1'
    @con.prepare 'findQuestionNameByID', 'SELECT p.name FROM assessment_questions p WHERE p.id = $1'
    @con.prepare 'findRuleDefinitionNameByID', 'SELECT p.name FROM rule_definition p WHERE p.id = $1'
    @con.prepare 'findPersonPersonByID', 'SELECT p.id, p.first_name, p.middle_name, p.last_name FROM person_person p WHERE p.id = $1'
    @con.prepare 'findUserDefinedRoleNameByID', 'SELECT p.name FROM permissionsuserdefinedrole p WHERE p.id = $1'
    @con.prepare 'findBjondTaskNameByID', 'SELECT p.name FROM bjondtask p WHERE p.id = $1'
    @con.prepare 'findAssessmentNameByID', 'SELECT p.name FROM assessment p WHERE p.id = $1'
    @con.prepare 'findRoleNameByID', 'SELECT p.name FROM roletypeentity p WHERE p.id = $1'
    @con.prepare 'findGroupNameByID', 'SELECT p.name FROM grouptypeentity p WHERE p.id = $1'
    @con.prepare 'findUserByID', 'SELECT p.id, p.loginname, p.firstname, p.lastname, p.email  FROM accounttypeentity p WHERE p.id = $1'
  end

  def version_of_libprg
    'Version of libpg: ' + PG.library_version.to_s
  end

  def find_tag_name_by_id(id)
    find_by_template 'findTagNameByID', id
  end

  def find_question_name_by_id(id)
    find_by_template 'findQuestionNameByID', id
  end

  def find_rule_definition_name_by_id(id)
    find_by_template 'findRuleDefinitionNameByID', id
  end

  def find_person_name_by_id(id)
    values = find_by_template('findPersonPersonByID', id)
    values.join('|') if values
  end

  def find_user_defined_role_name_by_id(id)
    find_by_template 'findUserDefinedRoleNameByID', id
  end

  def find_bjond_task_by_id(id)
    find_by_template 'findBjondTaskNameByID', id
  end

  def find_assessment_name_by_id(id)
    find_by_template 'findAssessmentNameByID', id
  end

  def find_role_name_by_id(id)
    find_by_template 'findRoleNameByID', id
  end

  def find_group_name_by_id(id)
    find_by_template 'findGroupNameByID', id
  end

  def find_user_by_id(id)
    values = find_by_template('findUserByID', id)
    values.join(',') if values
  end

  def close
    @con.close if @con
  end

  def find_by_template(statement_name, id)
    rs = @con.exec_prepared statement_name, [id]
    rs.values[0]
  rescue PG::Error => e
    puts e.message
  ensure
    rs.clear if rs
  end

  def read_audit_log(audit_log, outfile)
    f = File.new(outfile, 'w:UTF-8')
    CSV.foreach(audit_log,
                col_sep:  '|',
                headers:  false
               ) do |row|
      process_row(row, f)
    end
  end

  def process_row(row, file)
    @last_record_id = ''
    row.each do |element|
      next unless element
      tuple = element.split '='
      tuple[0].strip! if tuple[0]
      tuple[1].delete! "'" if tuple[1]
      line = "%s='%s'|" % [tuple[0], resolve(tuple[0], tuple[1])]
      file.print line
    end
    file.puts
  end

  def resolve(key, value)
    case key
    when 'ASSIGNED_TO',
        'ASSIGNOR',
        'ALREADYLOGGEDIN',
        'LOCKEDACCOUNT',
        'AUTHORIZATIONFAILURE',
        'LIMITEDIDENTITYCREATED',
        'ACCOUNTLOCKEDFORLOGIN',
        'ACCOUNTUNLOCKEDFORLOGIN',
        'PASSWORDVALIDATIONFAILUREFORLOGIN',
        'CLEAREDPASSWORDATTEMPTCOUNTERFORLOGIN',
        'IDENTITYCREATED',
        'IDENTITYDELETED',
        'LOGIN',
        'LOGOUT',
        'IDENTITY',
        'USER'
      find_user_by_id value

    when 'TASKSTATETRANSITIONTENANT',
        'TENANT',
        'GROUP',
        'GROUPCREATED',
        'GROUPDELETED',
        'GROUPROLEADDED',
        'GROUPROLEREVOKED',
        'DEFAULTTENANTDIVISIONCHANGEDGROUPID'
      find_group_name_by_id value

    when 'ROLECREATED',
        'ROLEDELETED',
        'ROLEGRANTED',
        'ROLEREVOKED',
        'ROLEUPDATED'
      find_role_name_by_id value

    when 'RECORDID&NAME',
        'CREATERECORDLOGIN',
        'READ/VIEWRECORDLOGIN',
        'UPDATERECORDLOGIN',
        'DELETERECORDLOGIN'
      @last_record_id = value
      value
    when 'CLASS'
      resolve_class value, @last_record_id
    else
      value
    end
  end

  def resolve_class(clazz, id)
    case clazz
    when 'com.bjond.persistence.assessment.Assessment'
      'Assessment: %s' % find_assessment_name_by_id(id)
    when 'com.bjond.persistence.task.BjondTask'
      'BjondTask: %s' % find_bjond_task_by_id(id)
    when 'com.bjond.persistence.permissions.UserDefinedRole'
      'UserDefinedRole: %s' % find_user_defined_role_name_by_id(id)
    when 'com.bjond.persistence.person.PersonPerson'
      'Person: %s' % find_person_name_by_id(id)
    when 'com.bjond.persistence.rule.RuleDefinition'
      'RuleDefinition: %s' % find_rule_definition_name_by_id(id)
    when 'com.bjond.persistence.tags.TagsFullText'
      'Tag: %s' % find_tag_name_by_id(id)
    else
      # Handles all questions identically.
      if clazz.start_with? 'com.bjond.persistence.assessment.Question'
        '%s: %s' % [clazz, find_question_name_by_id(id)]
      else
        id
      end
    end
  end
end

#brigid = Brigid.new 'localhost', 5432, 'bjond-health', 'bjondadmin', 'bjondadmin'
#brigid = Brigid.new ENV['POSTGRESQL_SERVER'],
#                    ENV['OPENSHIFT_POSTGRESQL_DB_PORT'],
#                    ENV['OPENSHIFT_APP_NAME'],
#                    ENV['ADAPTER_POSTGRESQL_DB_USERNAME'],
#                    ENV['ADAPTER_POSTGRESQL_DB_PASSWORD']

# puts brigid.version_of_libprg
# puts brigid.find_tag_name_by_id('0c51e93c-3a1f-11e5-b6bd-129ad806adaf')
# puts brigid.find_tag_name_by_id('0c51e93c-3a1f-11e5-b6bd-129ad806ada').nil?
#
# puts brigid.find_question_name_by_id('c57c26f8-3a0a-11e5-b6bd-129ad806adaf')
# puts brigid.find_rule_definition_name_by_id('d894491d-986a-11e5-ae77-0eb49f101791')
# puts brigid.find_person_name_by_id('07a82c50-5598-11e5-aa66-129ad806adaf')
# puts brigid.find_person_name_by_id('07a82c50-5598-11e5-aa66-129ad806ad').nil?
# puts brigid.find_user_defined_role_name_by_id('4c2d9c38-7ccf-11e5-98a5-0ebd4f99f70f')
# puts brigid.find_bjond_task_by_id('246c7a0c-5007-11e5-aa5b-129ad806adaf')
# puts brigid.find_assessment_name_by_id('3851a431-61fe-11e5-8cea-129ad806adaf')
# puts brigid.find_role_name_by_id('07c6790c-3277-466d-a448-9060d54531ae')
# puts brigid.find_group_name_by_id('4b6c668c-1e57-475d-8ae1-ee1e910d71c9')
# puts brigid.find_user_by_id('012afd5b-30f8-4a2d-80dc-ec68cdfc4eac')

#brigid.read_audit_log('secure-audit.log', 'outfile.log')
#brigid.close
