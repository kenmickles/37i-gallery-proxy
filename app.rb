$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'bundler'
Bundler.require :default, (ENV["RACK_ENV"] || "development").to_sym

set :host, 'http://gallery.37i.net.s3.amazonaws.com'

before do
  cache_control :public, max_age: 2629746 # 1 month
end

['/', '*.html'].each do |path|
  get path do
    # map the root to main.php
    path = request.fullpath == '/' ? '/main.php.html' : request.fullpath

    # fetch HTML from S3 host
    output = HTTParty.get("#{settings.host}#{path}").body

    # fix links with a plus in them
    output.gsub!(/\+/, '%2B')

    # ditch the old javascript
    output.gsub!(/<script type="text\/javascript" src="(.*)"><\/script>/, '')

    # add Google Analytics
    output.gsub!(/<\/head>/, "<script>
      (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
      (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
      m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
      })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

      ga('create', 'UA-300260-16', '37i.net');
      ga('send', 'pageview');
    </script>
    </head>")

    # add read-only message
    output.gsub!(/<\/body>/, "
      <script type='text/javascript'>
        var div = document.createElement('div');
        div.id = 'eviction-notice';
        div.innerHTML = 'This is a read-only archive of the old 37i photo gallery';
        document.body.appendChild(div);
      </script>
      <style type='text/css'>
        #eviction-notice {
          position: absolute;
          top: 0;
          left: 0;
          background: #000;
          color: white;
          right: 0;
          font-family: arial, sans-serif;
          padding: 7px;
          font-size: 13px;
          line-height: 1.4;
          text-align: center;
        }

        body, body.gallery {
          padding-top: 36px !important;
        }
      </style>
    </body>")

    output
  end
end

get '*.:format?' do
  redirect to "#{settings.host}#{request.fullpath}"
end