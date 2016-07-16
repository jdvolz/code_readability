post "/receive_sms/?" do
  body = params["Body"]

  reply_message = get_itpsss_facts

  if secret_id && body.length == 1 && body =~ /[12345]/
    secret = Secret.get(secret_id.to_i)
    rating_from_sms = params['Body'].to_i
    rating = Rating.create(:score => rating_from_sms)
    secret.ratings << rating
    secret.save

    twiml = Twilio::TwiML::Response.new do |r|
      r.Sms reply_message
    end
    twiml.text

  elsif body.length == 1 && body =~ /[12345]/

    message = "Sorry we couldn't match up the rating to a secret, that might because it's been more
              than 4 hours since you received last secret."
    twiml = Twilio::TwiML::Response.new do |r|
      r.Sms message
    end
    twiml.text

  else # it must be a secret!
    return_secret = Secret.first(:offset => rand(Secret.count))
    session["secretid"] = return_secret.id
    secret_id = return_secret.id


    secret = Secret.create(:body => params['Body'], :created_at => Time.now)
    caller = Caller.first_or_create(:from => params['From'])
    caller.secrets << secret
    caller.save

    twiml = Twilio::TwiML::Response.new do |r|
      r.Sms return_secret.body
    end
    twiml.text
  end
end
