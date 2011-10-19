require 'sinatra'
require 'datamapper'
require 'rack-flash'
require 'openid'
require 'openid/store/filesystem'
require 'fastercsv'
Dir[File.dirname(__FILE__) + '/models/*.rb'].each {|file| require file }
Dir[File.dirname(__FILE__) + '/helpers/*.rb'].each {|file| require file }

enable :sessions
use Rack::Flash


DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite://tmp/sqlite.db")
DataMapper.finalize
DataMapper.auto_upgrade!



get '/login' do
  erb :login
end

post '/login/openid' do
  openid = params[:openid_identifier]
  begin
    oidreq = openid_consumer.begin(openid)
  rescue OpenID::DiscoveryFailure => why
    "Sorry, we couldn't find your identifier #{openid} #{why}."
  else
    # You could request additional information here - see specs:
    # http://openid.net/specs/openid-simple-registration-extension-1_0.html
    # oidreq.add_extension_arg('sreg','required','nickname')
    # oidreq.add_extension_arg('sreg','optional','fullname, email')

    # Send request - first parameter: Trusted Site,
    # second parameter: redirect target
    redirect oidreq.redirect_url(root_url, root_url + "/login/openid/complete")
  end
end

get '/login/openid/complete' do
  oidresp = openid_consumer.complete(params, request.url)
  openid = oidresp.display_identifier

  case oidresp.status
    when OpenID::Consumer::FAILURE
      "Sorry, we could not authenticate you with this identifier #{openid}."

    when OpenID::Consumer::SETUP_NEEDED
      "Immediate request failed - Setup Needed"

    when OpenID::Consumer::CANCEL
      "Login cancelled."

    when OpenID::Consumer::SUCCESS
      # Access additional informations:
      # puts params['openid.sreg.nickname']
      # puts params['openid.sreg.fullname']

      "Login successfull."  # startup something
      session[:authenticated] = true
      redirect '/'
  end
end

get '/logout' do
  session[:authenticated] = false
  redirect '/login'
end


get '/' do
  redirect '/login' if !session[:authenticated]
  erb :index
end

post '/' do
  redirect '/login' if !session[:authenticated]
  begin
    @total_amount = 0
    begin
      csv = CSV.open(params['data_file'][:tempfile], {:headers => true, :col_sep => "\t", :row_sep => :auto})
    rescue CSV::MalformedCSV
	"BAD CSV file"
    end
    csv.each do |row|
      next if row.header_row?
      row= row.to_hash
      t = Transaction.create(:purchaser_name => row["purchaser name"].to_s,
			:item_description => row["item description"].to_s,
			:item_price => row["item price"].to_f,
			:purchase_count => row["purchase count"].to_i,
			:merchant_address => row["merchant address"].to_s,
			:merchant_name => row["merchant name"].to_s
		       )
      raise "invalid data" if !t.saved?
      puts "invalid data" if !t.saved?
      @total_amount += row["item price"].to_f*row["purchase count"].to_i
    end
    erb :results
  rescue Exception => whathappend
    "Problem parsing the file: #{whathappend}"
  end
end
