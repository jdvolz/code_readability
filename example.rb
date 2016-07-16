post '/receive_sms/?' do
  body = params['Body']
  from = params['From']

  handler = SmsReceivedHandler.new(body, from)
  handler.respond
end

class SmsReceivedHandler

  def initialize(body, from)
    @body = body
    @from = from
  end

  def respond
    if secret_id && is_integer_one_through_five(@body) #secret_id is not set, probably a bug
      reply_message = successful_secret_count(secret_id.to_i, @body.to_i)

    elsif is_integer_one_through_five(@body)

      reply_message = "Sorry we couldn't match up the rating to a secret, that might because it's been more than 4 hours since you received last secret."
    else
      reply_message = create_caller_from_secret(@body, @from)
    end

    twiml = send_twilio_response(reply_message)
    twiml.text
  end

  def successful_secret_and_count(secret_id, body)
    secret = Secret.get(secret_id)
    rating_from_sms = body
    rating = Rating.create(:score => rating_from_sms)
    secret.ratings << rating
    secret.save

    return get_itpsss_facts
  end

  def create_caller_from_secret(body, from  )
    return_secret = Secret.first(:offset => rand(Secret.count))
    session['secretid'] = return_secret.id
    secret_id = return_secret.id # secret_id set here, but never used again

    secret = Secret.create(:body => body, :created_at => Time.now)
    caller = Caller.first_or_create(:from => from)
    caller.secrets << secret
    caller.save

    return return_secret.body
  end

  def is_integer_one_through_five(str)
    str =~ /^[1-5]$/
  end

  def send_twilio_response(message)
    Twilio::TwiML::Response.new {|r| r.Sms message }
  end
end
