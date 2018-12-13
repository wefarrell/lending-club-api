require 'sinatra/activerecord'
require 'sinatra'

set :database, {adapter: "postgresql", database: "lc_dataset"}

