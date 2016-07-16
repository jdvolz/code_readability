
def is_integer_one_through_five(str)
  str =~ /^[1-5]$/
end

def send_twilio_response(message)
  Twilio::TwiML::Response.new {|r| r.Sms message }
end

post '/receive_sms/?' do
  body = params['Body']

  if secret_id && is_integer_one_through_five(body) #secret_id is not set, probably a bug
    secret = Secret.get(secret_id.to_i)
    rating_from_sms = body.to_i
    rating = Rating.create(:score => rating_from_sms)
    secret.ratings << rating
    secret.save

    reply_message = get_itpsss_facts
  elsif is_integer_one_through_five(body)
    reply_message = "Sorry we couldn't match up the rating to a secret, that might because it's been more than 4 hours since you received last secret."
  else
    return_secret = Secret.first(:offset => rand(Secret.count))
    session['secretid'] = return_secret.id
    secret_id = return_secret.id # secret_id set here, but never used again

    secret = Secret.create(:body => body, :created_at => Time.now)
    caller = Caller.first_or_create(:from => params['From'])
    caller.secrets << secret
    caller.save

    reply_message = return_secret.body
  end
  twiml = send_twilio_response(reply_message)
  twiml.text
end
