module Db2c
  class Command

    include CONSTANTS
    @@cdb = ''

    def initialize input
      if input
        puts "initializing: #{input}" if $DB2CDBG
        @input = input.chomp.strip.gsub(/^db2 /i,'')
        parse unless @input =~ /^(select|update|delete|insert)/i
      end
    end

    def to_s
      @input
    end

    def parse
      @input.gsub! /^use /, 'connect to '

      @input.gsub! /^\\d /, 'describe '
      if @input =~ /describe [^. ]+\.[^.+ ]+/
        @input.gsub! /describe /, 'describe table '
        return
      end

      if @input =~ /^(show|list) databases/ || @input == '\l'
        @input = "list database directory"
        return
      end

      if @input =~ /^\\lt ?(\w*)$/
        @input = "list tables"
        unless $1.empty?
          @input += $1 == "all" ? " for all" : " for schema #{$1}"
        end
        return
      end

      if @input =~ /^\\d([a|s|t|v]) ?(\w*)$/
        @input = DTSELECT
        @input += " where type = '#{$1.upcase}'"
        @input += " and tabschema = '#{$2.upcase}'" unless $2.empty?
        @input += " #{DTORDER}"
        return
      end

      if @input =~ /^\\dd([d|t]?) ([^. ]+)\.([^.+ ]+)/
        @input = "select substr(colname, 1, 40) as colname, substr(typeschema, 1, 10) as typeschema, substr(typename, 1, 20) as typename"
        @input += ", length, scale, nulls, substr(default, 1, 20) as default, generated, substr(text, 1, 40) as text" if $1 != "t"
        @input += ", generated, substr(text, 1, 100) as text" if $1 == "t"
        @input += " from syscat.columns"
        @input += " where tabschema = '#{$2.upcase}'"
        @input += " and tabname = '#{$3.upcase}'"
        @input += " order by colno"
        return
      end

      if @input =~ /^\\di ([^. ]+)\.([^.+ ]+)/
        @input = "select substr(i.indschema, 1, 20) as indschema, substr(i.indname, 1, 30) as indname, i.uniquerule,"
        @input += " substr(c.colname, 1, 40) as colname, c.colseq as colseq, c.colorder as colorder"
        @input += " from SYSCAT.indexes i"
        @input += " inner join SYSCAT.indexcoluse c"
        @input += " on i.indschema=c.indschema and i.indname=c.indname"
        @input += " where tabschema = '#{$1.upcase}'"
        @input += " and tabname = '#{$2.upcase}'"
        @input += " order by i.indschema, i.indname, c.colseq"
        return
      end

      if @input =~ /^\\dc ([^. ]+)\.([^.+ ]+)/
        @input = "select substr(t.constname, 1, 30) as constname, t.type as type, t.enforced as enforced,"
        @input += " substr(c.colname, 1, 40) as colname, c.colseq as colseq"
        @input += " from SYSCAT.tabconst t"
        @input += " inner join syscat.keycoluse c"
        @input += " on t.constname=c.constname"
        @input += " where t.tabschema = '#{$1.upcase}'"
        @input += " and t.tabname = '#{$2.upcase}'"
        @input += " order by t.constname, c.colseq"
        return
      end

      if @input =~ /^\\dp ?(\w*)$/
        @input = "select char(strip(tbspace), 15) as tbspace, char(strip(tabschema) || '.' || strip(tabname), 128) as table from syscat.tables"
        @input += " where type in ('T','V')"
        @input += " and tabschema = '#{$1.upcase}'" unless $1.empty?
        @input += " #{DTORDER}"
        return
      end

      if @input =~ /^\\size ([^. ]+)\.?([^.+ ]*)/
        @input = "select substr(tabschema,1,30) as tabschema, substr(tabname,1,30) as tabschema,"
        @input += " sum(data_object_p_size)+sum(index_object_p_size)+ sum(long_object_p_size)+sum(lob_object_p_size)+ sum(xml_object_p_size) as total_size,"
        @input += " sum(data_object_p_size) as data_object_p_size, sum(index_object_p_size) as index_object_p_size,"
        @input += " sum(long_object_p_size) as long_object_p_size, sum(lob_object_p_size) as lob_object_p_size,"
        @input += " sum(xml_object_p_size) as xml_object_p_size"
        @input += " from SYSIBMADM.admintabinfo"
        @input += " where tabschema = '#{$1.upcase}'"
        @input += " and tabname = '#{$2.upcase}'" unless $2.empty?
        @input += " group by tabschema,tabname"
        return
      end

      if @input =~ /^\\status ?(\w*)$/
        @input = "select varchar(tabschema,30) as tabschema,varchar(tabname,30) as tabname,status,access_mode from SYSCAT.tables"
        @input += " where tabschema ='#{$1.upcase}'"
        @input += " order by tabname"
        return
      end

      if @input =~ /^\\pending ?(\w*)$/
        @input = "select varchar(tabschema,30) as tabschema,varchar(tabname,30) as tabname,reorg_pending,num_reorg_rec_alters from SYSIBMADM.admintabinfo"
        @input += " where tabschema ='#{$1.upcase}'"
        @input += " order by tabname"
        return
      end

      shortcuts
    end

    def shortcuts
      prepend /^\-\d+$/, "? sql"
      prepend /^\d+$/, "? "
      prepend /^current.+$/i, "values "
    end

    def prepend regex, value
      @input.insert 0, value if @input =~ regex
    end

    def quit?
      @input.nil? || @input =~ /^(exit|quit|\\q|\\quit)$/
    end

    def history?
      @input =~ /^(history|hist|\\history|\\hist)$/
    end

    def help?
      @input =~ /^(help|h|\\help|\\h)$/
    end

    def valid?
      !quit? && !history? && !help?
    end

    def execute
      puts "executing: #{@input}" if $DB2CDBG
      if valid? && system('db2', @input)
        if @input =~ /^connect to (.*)$/i
          @@cdb = $1.downcase
        end
        if @input =~ /^disconnect #{@@cdb}$/i || @input =~ /^connect reset$/i
          @@cdb = ''
        end
      end
    end

    def self.prompt
      "db2c".tap do |pr|
        pr << "(#{@@cdb})" if @@cdb.length > 0
        pr << " => "
      end
    end

    def self.execute command
      new(command).execute
    end

  end
end
