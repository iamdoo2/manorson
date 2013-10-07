require 'net/https'
class AgeController < ApplicationController

  CLIENT_ID = '610618668989552'
  APP_PAGE_URL = 'http://www.facebook.com/LarmeDeSennen?sk=app_610618668989552'

  def show
    signed_request = Base64.decode64(params[:signed_request].split(".")[1]+"==")
    data = JSON.parse(signed_request)
    locale = data['user']['locale'].split("_")[0]
    I18n.locale = locale
    if data['page']['liked'] == false
      render :action => :welcome and return
    else
      http = facebook_connection
      token = data['oauth_token']
      if token.nil?
        render :text => "<script>window.top.location = 'https://www.facebook.com/dialog/oauth?client_id=#{CLIENT_ID}&scope=publish_stream&redirect_uri=#{APP_PAGE_URL}';</script>" and return
      end
      uid = data['user_id']
      user = User.where(uid: uid).first
      if user.nil?
        res = http.get('/me?access_token='+token)
        raise Exception if res.code != '200'
        api_data = JSON.parse(res.body)
        gender = nil
        if api_data['gender'] == 'male'
          gender = true
        else
          gender = false
        end
        user = User.create(token: token, uid: api_data['id'], name: api_data['name'], gender: gender, locale: locale)
      else
        user.update_attributes(token: token, locale: locale)
      end
      session[:user_id] = user.id
      collect_data(user)
    end
  end

  def publish
    raise Exception if session[:user_id].nil?
    user = User.find(session[:user_id])
    data = JSON.parse(user.data)
    message = "I have #{data['male']} male friends and #{data['female']} female friends. Check yours at https://apps.facebook.com/fbfriendanalyzer!"
    RestClient.post('https://graph.facebook.com/me/photos?access_token='+user.token, source: image(user.gender, data['male'], data['female']), message: message)
    render :text => message
  end

  private
    def facebook_connection
      http = Net::HTTP.new('graph.facebook.com', 443)
      http.use_ssl = true
      http
    end

    def collect_data(user)
      http = facebook_connection
      resp = http.get('/me/friends?fields=name,gender&access_token='+user.token)
      result = []
      data = JSON.parse(resp.body)
      count = {male: 0, female: 0}
      data['data'].each do |d|
        gender = nil
        if d['gender'] == 'male'
          gender = true
          count[:male] += 1
        else
          gender = false
          count[:female] += 1
        end
        result << [d['name'], gender]
      end
      user.update_attributes(data: count.to_json)
      @result = result.to_json
    end

    def image(gender, male, female)
      mimg = Magick::Image.read("#{Rails.root}/app/assets/images/male.png").first
      fimg = Magick::Image.read("#{Rails.root}/app/assets/images/female.png").first
      width = mimg.columns
      height = mimg.rows
      header = 70
      offset = 70
      margin = 10
      img = Magick::Image.new(width*10+margin*2,height*5+header+offset+margin*2)
      img.format = 'png'
      mratio = (male.to_f*50/(male+female)).round
      fratio = (female.to_f*50/(male+female)).round
      if mratio+fratio>50
        if mratio>fratio
          mratio-=1
        else
          fratio-=1
        end
      end
      0.upto(9) do |i|
        4.downto(0) do |j|
          img.composite!(mimg,i*width+margin,j*height+header+offset+margin,Magick::OverCompositeOp) if mratio>0
          mratio-=1
        end
      end
      9.downto(0) do |i|
        0.upto(4) do |j|
          img.composite!(fimg,i*width+margin,j*height+header+offset+margin,Magick::OverCompositeOp) if fratio>0
          fratio-=1
        end
      end
      text = Magick::Draw.new
      text.annotate(img,0,0,margin,margin,"My FB Friends") {
        self.gravity = Magick::NorthWestGravity
        self.pointsize = 48
        self.font_family = 'FreeSans'
        self.fill = '#666'
      }
      mtext = Magick::Draw.new
      mtext.annotate(img,0,0,margin,header+margin,male.to_s) {
        self.gravity = Magick::NorthWestGravity
        self.pointsize = 36
        self.font_family = 'FreeSans'
        self.fill = '#6FA8DC'
      }
      mtext.annotate(img,0,0,margin,header+margin+40,"Male") {
        self.gravity = Magick::NorthWestGravity
        self.pointsize = 24
        self.font_family = 'FreeSans'
        self.fill = '#6FA8DC'
      }
      ftext = Magick::Draw.new
      ftext.annotate(img,0,0,margin,header+margin,female.to_s) {
        self.gravity = Magick::NorthEastGravity
        self.pointsize = 36
        self.font_family = 'FreeSans'
        self.fill = '#EA9999'
      }
      ftext.annotate(img,0,0,margin,header+margin+40,"Female") {
        self.gravity = Magick::NorthEastGravity
        self.pointsize = 24
        self.font_family = 'FreeSans'
        self.fill = '#EA9999'
      }
      tempfile = Tempfile.new("#{gender}_#{male}_#{female}")
      img.write(tempfile.path)
      tempfile
    end

end
