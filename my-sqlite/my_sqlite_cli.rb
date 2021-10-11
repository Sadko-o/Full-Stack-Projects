require "readline"
require "./my_sqlite_request.rb"

class Cli < MySqliteRequest
    def initialize
        @user_query
        @insert_hash = {}
        @set_keys=[]
        @set_values=[]
        @insert_query
        @join_query
    end

    def parse_values(query)
        query_values = []
        @user_query.each_index do |index|
            if (@user_query[index] == query)
                index += 1

                if @user_query[index-1]=='ON'
                    query_values.push(@user_query[index]) 
                    query_values.push(@user_query[index+2])
                    return query_values
                end   

                if (@user_query[index].start_with?'(')           
                    line = @user_query[index]
                    line.gsub!('(', '')
                    line.gsub!(')', '')
                    @user_query[index] = line
                    query_values = @user_query[index].split(',')   
                
                    #puts "Line 33"
                    return query_values
                end

                if (@user_query[index-1]=='SET' && @user_query[index+1] == '=')           
                    @set_keys.push(@user_query[index]) 
                    @set_values.push(@user_query[index+2].gsub!(",", ""))  
                    index+=3
                    while @user_query[index]!='WHERE'
                        @set_keys.push(@user_query[index]) 
                        @set_values.push(@user_query[index+2])  
                        index+=3   
                    end    
                    return nil
                end

                if @user_query[index].include?(',')
                    args=[]
                    args= @user_query[index].split(',')        
                else
                    args= @user_query[index]
                end

                #p args
                query_values.push(args)
                
                if (@user_query[index+1] == '=' && @user_query[index-1]=='WHERE')    
                    query_values.push(@user_query[index+2])
                    return query_values
                end
                #puts ":::query:::"
                #p query_values
            return query_values
            end
        end    
    end

    def all_columns(table_name)
        if table_name.end_with?('.csv')
            @file_name = table_name
        else
            @file_name = table_name + '.csv'
        end
        data_array = CSV.parse(File.read(@file_name))
        cols = data_array.shift
        return cols
    end

    def check_csv(table_name)
        if table_name.end_with?('.csv')
            return table_name
        end
        return table_name + '.csv'
    end

    def parse_query(command_line)
        @user_query = command_line.split()
        #p @user_query
        @user_query.each do |query|
            case query
                when 'SELECT'
                    select_query = parse_values('SELECT')
                    @request = @request.select(*select_query)

                when 'INSERT'        
                    if @user_query[1] != 'INTO'
                    STDERR.puts "ERROR: Missing WORD \nCorrect form: INSERT INTO"
                    else
                    @user_query.slice!(1)
                    @insert_query = parse_values('INSERT')
                    #p @insert_query
                    @insert_query = check_csv(*@insert_query[0])
                    #p @insert_query
                    @request = @request.insert(*@insert_query)
                    end

                when 'VALUES'      
                    values_query = parse_values('VALUES')
                    cols = all_columns(*@insert_query)
                    values_query.each_index do |index|
                    @insert_hash["#{cols[index]}"] = values_query[index]
                    end
                    @request = @request.values(@insert_hash)

                when 'UPDATE'      
                    update_query = parse_values('UPDATE')
                    update_query = check_csv(*update_query[0])
                    
                    @request = @request.update(*update_query)

                when 'SET'             
                    set_query = parse_values('SET')
                    set_query_hash = {}
                    index = 0
                    size = @set_keys.length()
                    while index < size
                    set_query_hash["#{@set_keys[index]}"] = @set_values[index].gsub!("'","")
                    index += 1
                    #puts "Hash"
                    #p set_query_hash

                    end
                    @request = @request.set(set_query_hash)

                when 'DELETE'       
                    delete_query = parse_values('DELETE')
                    @request = @request.delete

                when 'FROM'          
                    from_query = parse_values('FROM')
                    from_query = check_csv(from_query[0])
                    @request = @request.from(*from_query) 

                when 'WHERE'           
                    where_query = parse_values('WHERE')
                    column_name = where_query[0]       
                    criteria = where_query[1].gsub("'", "")        
                    @request = @request.where(column_name,criteria)

                when 'JOIN'
                    @join_query = parse_values('JOIN')

                when 'ON'
                    on_query = parse_values('ON')
                    @request = @request.join(on_query[0],@join_query[0],on_query[1])
            end
        end
    end


    def run
        puts 'MySQLite version 0.1 2021-07-15'
        input = Readline.readline("my_sqlite_cli> ", true)    
        while input != 'quit'
            @request = MySqliteRequest.new
            parse_query(input)    
            @request.run
            input = Readline.readline("my_sqlite_cli> ", true)
        end
    end
end



cli = Cli.new.run