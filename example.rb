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
    reply_message = create_reply_message(secret_id, @body, @from)

    twiml = send_twilio_response(reply_message)
    twiml.text
  end

  private

  def create_reply_message(secret_id, body, from)
    reply_message = if secret_id && is_integer_one_through_five(body) #secret_id is not set, probably a bug
      successful_secret_customer_rating(secret_id, body.to_i)
    elsif is_integer_one_through_five(body)
      "Sorry we couldn't match up the rating to a secret, that might because it's been more than 4 hours since you received last secret."
    else
      create_caller_from_secret(body, from)
    end

    return reply_message
  end

  def successful_secret_and_customer_rating(secret_id, customer_rating)
    secret = Secret.get(secret_id)
    rating = Rating.create(:score => customer_rating)
    secret.ratings << rating
    secret.save

    return get_itpsss_facts
  end

  def create_caller_from_secret(body, from)
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
