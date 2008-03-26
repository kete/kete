module AccountHelper

  def String.random_alphanumeric(size=16)
    (1..size).collect { (i = Kernel.rand(62); i += ((i < 10) ? 48 : ((i < 36) ? 55 : 61 ))).chr }.join
  end

  def generate_captcha
    #Define an array of words for generation
    #words = ['captcha', 'is', 'the', 'way']
    #Pick one from random to use in captcha image
    captchatext = String.random_alphanumeric(6).upcase # words[rand(words.size)]

    #Generate text layer
    text = Magick::Draw.new
    text.pointsize = 25
    # see comment below around pushing new image to canvas
    text.fill = 'darkblue'
    text.gravity = Magick::CenterGravity
    #Rotate text 5 degrees up or down
    text.rotation = (rand(2)==1 ? 5 : -5)

    #Provide the text
    metric = text.get_type_metrics(captchatext)

    #Define image list
    canvas = Magick::ImageList.new

    #Add bg image to image list
    canvas << Magick::Image.new(metric.width, metric.height){
      self.background_color = '#fff'
    }

    # Add text to image list
    # Walter McGinnis, 2008-03-27
    # thanks to Mark de Reeper at Sun
    # for pointing in the direction of a fix for making this work across platforms
    # by setting the background to white and the text to darkblue
    # this should be explictly readable
    canvas << Magick::Image.new(metric.width, metric.height){
      self.background_color = 'white'
    }.annotate(text, 0, 0, 0, 0, captchatext).wave(3, 100)

    #Add noise and opacity to image
    canvas << Magick::Image.new(metric.width, metric.height){
      p = Magick::Pixel.from_color('#fff')
      p.opacity = Magick::MaxRGB/2
      self.background_color = p
    }.add_noise(Magick::LaplacianNoise)

    #Create image resource
    image = canvas.flatten_images.blur_image(1)
    image.format = "JPG"
    captchablob = image.to_blob

    captcha = Captcha.new()
    captcha.text = captchatext.to_s()
    captcha.imageblob = captchablob
    captcha.save()
    return captcha.id
  end

  def captcha_url(id)
    return url_for(:controller => "account", :action => "show_captcha",
                   :id => id, :time => Time.now())
  end
end
