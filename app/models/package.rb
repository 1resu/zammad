# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

require 'rexml/document'
class Package < ApplicationModel
  @@root = Rails.root.to_s

  # build package based on .szpm
  # Package.build(
  #   :file   => 'package.szpm',
  #   :root   => '/path/to/src/extention/',
  #   :output => '/path/to/package_location/'
  # )
  def self.build(data)

    if data[:file]
      xml     = self._read_file( data[:file], data[:root] || true )
      package = self._parse(xml)
    elsif data[:string]
      package = self._parse( data[:string] )
    end

    build_date = REXML::Element.new('build_date')
    build_date.text = Time.now.utc.iso8601
    build_host = REXML::Element.new('build_host')
    build_host.text = Socket.gethostname

    package.root.insert_after( '//zpm/description', build_date )
    package.root.insert_after( '//zpm/description', build_host )
    package.elements.each('zpm/filelist/file') do |element|
      location = element.attributes['location']
      content = self._read_file( location, data[:root] )
      base64  = Base64.encode64(content)
      element.text = base64
    end
    if data[:output]
      location = data[:output] + '/' + package.elements['zpm/name'].text + '-' + package.elements['zpm/version'].text + '.zpm'
      logger.info "NOTICE: writting package to '#{location}'"
      file = File.new( location, 'wb' )
      file.write( package.to_s )
      file.close
      return true
    end
    package.to_s
  end

  # Package.auto_install
  # install all packages located under auto_install/*.zpm
  def self.auto_install
    path = @@root + '/auto_install/'
    return if ! File.exist?( path )
    data = []
    Dir.foreach( path ) do |entry|
      if entry =~ /\.zpm/ && entry !~ /^\./
        data.push entry
      end
    end
    data.each {|file|
      self.install( :file => path + '/' + file )
    }
    data
  end

  # Package.unlink_all
  # remove all linked files in application
  # note: will not take down package migrations, use Package.unlink instead
  def self.unlink_all
    # link files
    Dir.glob( @@root + '/**/*' ) do |entry|
      if File.symlink?( entry)
        logger.info "unlink: #{entry}"
        File.delete( entry )
      end
      backup_file = entry + '.link_backup'
      if File.exists?( backup_file )
        logger.info "Restore backup file of #{backup_file} -> #{entry}."
        File.rename( backup_file, entry )
      end
    end
  end

  # check if zpm is a package source repo
  def self._package_base_dir?(package_base_dir)
    package = false
    Dir.glob(  package_base_dir + '/*.szpm') do |entry|
      package = entry.sub( /^.*\/(.+?)\.szpm$/, '\1')
    end
    if package == false
      raise "Can't link package, '#{package_base_dir}' is no package source directory!"
    end
    logger.debug package.inspect
    package
  end

  # Package.unlink('/path/to/src/extention')
  # execute migration down + unlink files
  def self.unlink(package_base_dir)

    # check if zpm is a package source repo
    package = self._package_base_dir?(package_base_dir)

    # migration down
    Package::Migration.migrate( package, 'reverse' )

    # link files
    Dir.glob( package_base_dir + '/**/*' ) do |entry|
      entry = entry.sub( '//', '/' )
      file = entry
      file = file.sub( /#{package_base_dir.to_s}/, '' )
      dest = @@root + '/' + file

      if File.symlink?( dest.to_s )
        logger.info "Unlink file: #{dest.to_s}"
        File.delete( dest.to_s )
      end

      backup_file = dest.to_s + '.link_backup'
      if File.exists?( backup_file )
        logger.info "Restore backup file of #{backup_file} -> #{dest.to_s}."
        File.rename( backup_file, dest.to_s )
      end
    end
  end

  # Package.link('/path/to/src/extention')
  # link files + execute migration up
  def self.link(package_base_dir)

    # check if zpm is a package source repo
    package = self._package_base_dir?(package_base_dir)

    # link files
    Dir.glob( package_base_dir + '/**/*' ) do |entry|
      entry = entry.sub( '//', '/' )
      file = entry
      file = file.sub( /#{package_base_dir.to_s}/, '' )
      file = file.sub( /^\//, '' )

      # ignore files
      if file =~ /^README/
        logger.info "NOTICE: Ignore #{file}"
        next
      end

      # get new file destination
      dest = @@root + '/' + file

      if File.directory?( entry.to_s )
        if !File.exists?( dest.to_s )
          logger.info "Create dir: #{dest.to_s}"
          FileUtils.mkdir_p( dest.to_s )
        end
      end

      if File.file?( entry.to_s ) && ( File.file?( dest.to_s ) && !File.symlink?( dest.to_s ) )
        backup_file = dest.to_s + '.link_backup'
        if File.exists?( backup_file )
          raise "Can't link #{entry.to_s} -> #{dest.to_s}, destination and .link_backup already exists!"
        else
          logger.info "Create backup file of #{dest.to_s} -> #{backup_file}."
          File.rename( dest.to_s, backup_file )
        end
      end

      if File.file?( entry )
        if File.symlink?( dest.to_s )
          File.delete( dest.to_s )
        end
        logger.info "Link file: #{entry.to_s} -> #{dest.to_s}"
        File.symlink( entry.to_s, dest.to_s )
      end
    end

    # migration up
    Package::Migration.migrate( package )
  end

  # Package.install( :file => '/path/to/package.zpm' )
  # Package.install( :string => zpm_as_string )
  def self.install(data)
    if data[:file]
      xml     = self._read_file( data[:file], true )
      package = self._parse(xml)
    elsif data[:string]
      package = self._parse( data[:string] )
    end

    # package meta data
    meta = {
      :name           => package.elements['zpm/name'].text,
      :version        => package.elements['zpm/version'].text,
      :vendor         => package.elements['zpm/vendor'].text,
      :state          => 'uninstalled',
      :created_by_id  => 1,
      :updated_by_id  => 1,
    }

    # verify if package can get installed
    package_db = Package.where( :name => meta[:name] ).first
    if package_db
      if !data[:reinstall]
        if Gem::Version.new( package_db.version ) == Gem::Version.new( meta[:version] )
          raise "Package '#{meta[:name]}-#{meta[:version]}' already installed!"
        end
        if Gem::Version.new( package_db.version ) > Gem::Version.new( meta[:version] )
          raise "Newer version (#{package_db.version}) of package '#{meta[:name]}-#{meta[:version]}' already installed!"
        end
      end

      # uninstall files of old package
      self.uninstall({
        :name               => package_db.name,
        :version            => package_db.version,
        :migration_not_down => true,
      })
    end

    # store package
    record = Package.create( meta )
    if !data[:reinstall]
      Store.add(
        :object        => 'Package',
        :o_id          => record.id,
        :data          => package.to_s,
        :filename      => meta[:name] + '-' + meta[:version] + '.zpm',
        :preferences   => {},
        :created_by_id => UserInfo.current_user_id || 1,
      )
    end

    # write files
    package.elements.each('zpm/filelist/file') do |element|
      location   = element.attributes['location']
      permission = element.attributes['permission'] || '644'
      base64     = element.text
      content    = Base64.decode64(base64)
      content    = self._write_file(location, permission, content)
    end

    # update package state
    record.state = 'installed'
    record.save

    # reload new files
    Package.reload_classes

    # up migrations
    Package::Migration.migrate( meta[:name] )

    # prebuild assets

    true
  end

  # Package.reinstall( package_name )
  def self.reinstall(package_name)
    package = Package.where( :name => package_name ).first
    if !package
      raise "No such package '#{package_name}'"
    end

    file = self._get_bin( package.name, package.version )
    self.install( :string => file, :reinstall => true )
  end

  # Package.uninstall( :name => 'package', :version => '0.1.1' )
  # Package.uninstall( :string => zpm_as_string )
  def self.uninstall( data )

    if data[:string]
      package = self._parse( data[:string] )
    else
      file    = self._get_bin( data[:name], data[:version] )
      package = self._parse(file)
    end

    # package meta data
    meta = {
      :name           => package.elements['zpm/name'].text,
      :version        => package.elements['zpm/version'].text,
    }

    # down migrations
    if !data[:migration_not_down]
      Package::Migration.migrate( meta[:name], 'reverse' )
    end

    package.elements.each('zpm/filelist/file') do |element|
      location   = element.attributes['location']
      permission = element.attributes['permission'] || '644'
      base64     = element.text
      content    = Base64.decode64(base64)
      content    = self._delete_file(location, permission, content)
    end

    # prebuild assets

    # reload new files (only if we are in uninstall modus)
    if !data[:migration_not_down]
      Package.reload_classes
    end

    # delete package
    record = Package.where(
      :name     => meta[:name],
      :version  => meta[:version],
    ).first
    record.destroy

    true
  end

  # reload .rb files in case they have changed
  def self.reload_classes
    ['app', 'lib'].each {|dir|
      Dir.glob( Rails.root.join( dir + '/**/*') ).each {|entry|
        if entry =~ /\.rb$/
          begin
            load entry
          rescue => e
            puts "TRIED TO RELOAD '#{entry}'"
            puts 'ERROR: ' + e.inspect
            puts 'Traceback: ' + e.backtrace.inspect
          end
        end
      }
    }
  end

  def self._parse(xml)
    logger.debug xml.inspect
    begin
      package = REXML::Document.new( xml )
    rescue => e
      puts 'ERROR: ' + e.inspect
      return
    end
    logger.debug package.inspect
    package
  end

  def self._get_bin( name, version )
    package = Package.where(
      :name     => name,
      :version  => version,
    ).first
    if !package
      raise "No such package '#{name}' version '#{version}'"
    end
    list = Store.list(
      :object => 'Package',
      :o_id   => package.id,
    )

    # find file
    if !list || !list.first
      raise "No such file in storage list #{name} #{version}"
    end
    if !list.first.content
      raise "No such file in storage #{name} #{version}"
    end
    list.first.content
  end

  def self._read_file(file, fullpath = false)
    if fullpath == false
      location = @@root + '/' + file
    elsif fullpath == true
      location = file
    else
      location = fullpath + '/' + file
    end

    begin
      data = File.open( location, 'rb' )
      contents = data.read
    rescue => e
      raise 'ERROR: ' + e.inspect
    end
    contents
  end

  def self._write_file(file, permission, data)
    location = @@root + '/' + file

    # rename existing file
    if File.exist?( location )
      backup_location = location + '.save'
      logger.info "NOTICE: backup old file '#{location}' to #{backup_location}"
      File.rename( location, backup_location )
    end

    # check if directories need to be created
    directories = location.split '/'
    (0..(directories.length-2) ).each {|position|
      tmp_path = ''
      (1..position).each {|count|
        tmp_path = tmp_path + '/' + directories[count].to_s
      }
      if tmp_path != ''
        if !File.exist?(tmp_path)
          Dir.mkdir( tmp_path, 0755)
        end
      end
    }

    # install file
    begin
      logger.info "NOTICE: install '#{location}' (#{permission})"
      file = File.new( location, 'wb' )
      file.write( data )
      file.close
      File.chmod( permission.to_i(8), location )
    rescue => e
      raise 'ERROR: ' + e.inspect
    end
    true
  end

  def self._delete_file(file, permission, data)
    location = @@root + '/' + file

    # install file
    logger.info "NOTICE: uninstall '#{location}'"
    if File.exist?( location )
      File.delete( location )
    end

    # rename existing file
    backup_location = location + '.save'
    if File.exist?( backup_location )
      logger.info "NOTICE: restore old file '#{backup_location}' to #{location}"
      File.rename( backup_location, location )
    end

    true
  end

  class Migration < ApplicationModel
    @@root = Rails.root.to_s

    def self.migrate( package, direction = 'normal' )
      location = @@root + '/db/addon/' + package.underscore

      return true if !File.exists?( location )
      migrations_done = Package::Migration.where( :name => package.underscore )

      # get existing migrations
      migrations_existing = []
      Dir.foreach(location) {|entry|
        next if entry == '.'
        next if entry == '..'
        migrations_existing.push entry
      }

      # up
      migrations_existing = migrations_existing.sort

      # down
      if direction == 'reverse'
        migrations_existing = migrations_existing.reverse
      end

      migrations_existing.each {|migration|
        next if migration !~ /\.rb$/
        version = nil
        name    = nil
        if migration =~ /^(.+?)_(.*)\.rb$/
          version = $1
          name    = $2
        end
        if !version || !name
          raise "Invalid package migration '#{migration}'"
        end

        # down
        if direction == 'reverse'
          done = Package::Migration.where( :name => package.underscore, :version => version ).first
          next if !done
          logger.info "NOTICE: down package migration '#{migration}'"
          load "#{location}/#{migration}"
          classname = name.camelcase
          Kernel.const_get(classname).down
          record = Package::Migration.where( :name => package.underscore, :version => version ).first
          if record
            record.destroy
          end

          # up
        else
          done = Package::Migration.where( :name => package.underscore, :version => version ).first
          next if done
          logger.info "NOTICE: up package migration '#{migration}'"
          load "#{location}/#{migration}"
          classname = name.camelcase
          Kernel.const_get(classname).up
          Package::Migration.create( :name => package.underscore, :version => version )
        end

        # reload new files
        Package.reload_classes
      }
    end
  end
end