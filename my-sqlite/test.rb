require 'csv'
csv = CSV.open("test.csv", "a+")

csv << ["Tariq Abdul-Wahad",1998,2003,"F","6-6",223,"November 3, 1974","San Jose State University"]
