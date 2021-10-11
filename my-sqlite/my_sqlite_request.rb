=begin

<------------------RE-DO------------------>
["INSERT", "INTO", "students", "VALUES", "(John,john@johndoe.com,A,https://blog.johndoe.com)"]
"students"
"students.csv"
inserted 
Check it)
#<CSV:0x000055abbb454c48>
my_sqlite_cli> quit


=end

require 'csv'

class MySqliteRequest
    def initialize()
        @@type = nil
        @@table_name = nil
        @@select = []
        @@where = []
        @@order = "ASC"
        @@order_column = nil
        @@data = nil
        @@values = nil
        @@set = nil
        @@join_table = nil
        @@additional_data = nil
        @@join_columns = []
        @@file_name = nil
    end
    
    def from(table_name)
        if table_name.end_with?('.csv')
            @@file_name = table_name
        else
            @@file_name = table_name + '.csv'
        end
        
        self._setTable(table_name)
        return self
    end
    
    def select(column_name)
        self._setType("select")
        
        type = column_name.class
        
        if (type == String)
            if column_name == "*"
                @@select = nil
            else
                @@select = [column_name]
            end
        else
            column_name.each{ |column| @@select.push(column)}
        end
        
        return self
    end
    
    def where(column_name, criteria)
        @@where.push([column_name, criteria])
        return self
    end
    
    def order(order, column_name)
        @@order = order
        @@order_column = column_name
        return self
    end
    
    def join(column_on_db_a, filename_db_b, column_on_db_b)

        @@join_table = filename_db_b
        @@join_columns = [column_on_db_a, column_on_db_b]
        return self
    end

    def get_all_columns(table_name)
        if table_name.end_with?('.csv')
            @@file_name = table_name
        else
            @@file_name = table_name+'.csv'    
        end 
        
        data_array = CSV.parse(File.read(@@file_name))
        cols = data_array.shift
        return cols
    end

    def _runSelect()
       # p @@type
       # p @@table_name
       # p @@select
       # p @@where
       # p @@order
       # p @@join_table
       # p @@additional_data
       # p @@join_columns
        
        if (@@join_table)
            @join_column_values = []
            @@data = CSV.open(@@table_name, "r", headers:true).map do |row|
                new_row = {}

                row.each do |key, value|
                    string = @@table_name + "." + key
                    new_row[string] = value
                end

                if (@@join_table && !@join_column_values.include?(new_row[@@join_columns[0]]))
                    @join_column_values.push(new_row[@@join_columns[0]])
                end
                new_row
            end

            @@additional_data = CSV.open(@@join_table, "r", headers:true).map do |row|
                str = row[@@join_columns[1].split(@@join_table)[1].split('.')[1]]
                if (@join_column_values.include?(str))
                    new_row = {}
                    row.map do |key, value|
                        if key
                            string = @@join_table + "." + key
                            new_row[string] = value
                        end
                    end
                    new_row
                else
                    nil
                end
            end.compact

            @@data = @@data.map do |row|
                join_row = @@additional_data.select{|join_row| join_row[@@join_columns[1]] == row[@@join_columns[0]]}[0]
                @@additional_data[0].keys.each do |col_name|
                    # p col_name
                    if (col_name != @@join_columns[1])
                        if join_row
                            row[col_name] = join_row[col_name]
                        else
                            row[col_name] = nil
                        end
                    end
                end
                row
            end

            # p "All data"
            p @@data
        else
            @@data = CSV.open(@@table_name, "r", headers:true).map do |row|
                row = row.to_h
            end
        end

        @@data = @@data.map do |row|
            output = true
            @@where.each do |col|
                if (row[col[0]] != col[1])
                    output = false
                end
            end
            
            if output
                row
            else
                nil
            end
        end.compact
        
        if @@order_column
            @@data.sort_by!{ |row| row[@@order_column] }
            
            if (@@order == "DESC")
                @@data.reverse!
            end
        end
        
        if @@select
            @@data.map! do |row| 
                row.select! do |key, value| 
                    @@select.include?(key)
                end
            end
        end
        
        # p " "
        # p "<---- data ---->" 
        p @@data
    end
    
    def insert(table_name)
        self._setType("insert")
        self._setTable(table_name)
        puts "inserted \nCheck it)"
        return self
    end
    
    def values(data)
        @@values = data
        return self
    end
    
    def _runInsert()
        @@data = CSV.open(@@table_name, "a+", headers: true)
        headers = @@data.read.headers
        instance = {}
        headers.each do |header|
            if @@values.keys.include?(header)
                instance[header] = @@values[header]
            else
                instance[header] = ""
            end
        end

        @@data << instance.map{|key, value| value}
        @@data.close
    end

    def update(table_name)
        self._setType("update")
        self._setTable(table_name)
        return self
    end
    
    def set(data)
        @@set = data
        return self
    end
    
    def _runUpdate()
        @@data = CSV.read(@@table_name, headers: true).map do |row|
            output = true
            @@where.each do |col|
                if (row[col[0]] != col[1])
                    output = false
                end
            end
            
            if output
                @@set.each do |key, value|
                   row[key] = value
                end
            else
                row
            end
            
            row
        end

        csv = CSV.open(@@table_name, "w") do |csv| 
            @@data.each.with_index do |row, index|
                if index == 0
                    csv << row.map { |key, value| key }
                end
                csv << row.map { |key, value| value } 
            end 
        end
    end

    def delete()
        self._setType("delete")
        return self
    end
    
    def _runDelete()
        @@data = CSV.read(@@table_name, headers: true).map do |row|
            output = true
            @@where.each do |col|
                if (row[col[0]] != col[1])
                    output = false
                end
            end
            
            if output
                p row
                nil
            else
                row
            end
        end.compact

        csv = CSV.open(@@table_name, "w") do |csv| 
            @@data.each.with_index do |row, index|
                if index == 0
                    csv << row.map { |key, value| key }
                end
                csv << row.map { |key, value| value } 
            end 
        end
    end


    def run()
        if @@type == "select"
            self._runSelect()
        elsif @@type == "insert"
            self._runInsert()
        elsif @@type == "update"
            self._runUpdate()
        elsif @@type == "delete"
            self._runDelete()
        end
    end
    
    def _setTable(table_name)
        if ( @@table_name == nil || @@table_name == table_name )
            @@table_name = table_name
        else
            raise "Invalid table_name #{table_name}"
        end
    end
    
    def _setType(type)
        if ( @@type == nil || @@type == type )
            @@type = type
        else
            raise "Invalid type #{type}"
        end
    end
end

def _main()
    # request = MySqliteRequest.new
    # request = request.from('nba_player_data_lite')
    # request = request.select(['name', "year_start"])
    # request = request.where("year_start", "1991")
    # request = request.order("DESC", "name")

    # request = request.from('nba_player_data.csv')
    # request = request.select("*")
    # request = request.select(['nba_player_data.csv.name', "nba_players.csv.collage"])
    # request = request.join('nba_player_data.csv.name', 'nba_players.csv', 'nba_players.csv.Player')
    # request = request.where("nba_player_data.csv.year_start", "1991")
    # request = request.order("DESC", "name")

    # request = request.insert("nba_lite.csv")
    # request = request.values({"name"=> "Oleg", "year_end"=> 1995})
    # request = request.where("year_start", "1991")

    #request = request.update("nba_lite.csv")
    # request = request.set({"name"=>"Oleg", "year_end"=>1995})
    # request = request.where("year_start", "1991")

    # request = request.delete()
    # request = request.from('nba_lite.csv')
    # request = request.where("year_start", "1969")
    # request.run

    # request = MySqliteRequest.new
    # request = request.insert('nba_player_data_lite.csv')
    # request = request.values('name' => 'Alaa Abdelnaby', 'year_start' => '1991', 'year_end' => '1995', 'position' => 'F-C', 'height' => '6-10', 'weight' => '240', 'birth_date' => "June 24, 1968", 'college' => 'Duke University')
    # request.run

    request = MySqliteRequest.new
    request = request.update('students.csv')
    request = request.set({'email' => 'jane@janedoe.com','blog' => 'https://blog.janedoe.com'})
    request = request.where('name', 'John')
    request.run
    
    #request = request.update("nba_lite.csv")
    # request = request.set({"name"=>"Oleg", "year_end"=>1995})
    # request = request.where("year_start", "1991")
end

_main()
