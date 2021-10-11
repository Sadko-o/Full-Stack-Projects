require 'json'

class MySelectQuery
    @csv_table = []
    def initialize(csv)
        @csv_table = csv
    end

    def where(column_name, criteria)
        lines = @csv_table.split("\n")
        inner_words = lines[0].split(",")
        count_lines = lines.size
        count_words = inner_words.size
        hash_row = []

        for i in 0...count_lines
            hash = Hash.new
            for j in 0..count_words
                row_i = lines[i].split(",")
                hash[inner_words[j]] = row_i[j]
            end
            hash_row.push(hash)
        end

        
        for i in 0...count_words
            if inner_words[i] == column_name
                column_index = i
            end
        end
    
        for i in 0...count_lines
            line = lines[i].split(",")
            if line[column_index] == criteria
                row_index = i
            end
        end

        
        ret = []
        for i in 0...count_words
            ret[i] = hash_row[row_index][inner_words[i]]
        end

        arrr = [] 
        arrr[0] = ret.join(",")
        return arrr
    end
end
