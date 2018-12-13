US_STATES = %w(AK AL AR AZ CA CO CT DC DE FL GA HI IA ID IL IN KS KY LA MA MD ME MI MN MO MS MT NC ND NE NH NJ NM NV NY OH OK OR PA RI SC SD TN TX UT VA VT WA WI WV WY)


configure do
  enable :cross_origin
end

before do
  response.headers['Access-Control-Allow-Origin'] = '*'
  content_type :json
end

get '/states/?:state' do
  where_clause = "WHERE addr_state = '#{state}'" if state
  sql = <<-SQL
    SELECT count(*),
      avg(loan_amnt) AS avg_loan,
      avg(annual_inc) AS avg_income,
      purpose
    FROM lc_dataset
    #{where_clause}
    GROUP BY purpose
  SQL
  query(sql)
end

after do
  response.body = JSON.dump(response.body)
end

def state
  params[:state] if US_STATES.include?(params[:state])
end


def query(sql)
  ActiveRecord::Base.connection.execute(sql).to_a
end
