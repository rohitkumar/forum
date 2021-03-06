class MembersController < ApplicationController

   before_filter :authenticate1_user , :only =>[:dashboard]
#  def index
#    if session['access_token']
#      @face='You are logged in! <a href="facebooks/logout">Logout</a>'
#    else
#      @face='<a href="users/login">Login</a>'
#    end
#  end  
# 
  
  def filldetails
    
    if session['access_token']
      @graph = Koala::Facebook::API.new(session["access_token"])
      userinfo =  @graph.get_object("me")
      @user = User.new
      @user.firstname = userinfo['first_name']
      @user.lastname = userinfo['last_name']
      @user.username = userinfo['username']
      unless userinfo['location'] == nil
        @user.city = userinfo['location']['name']
      end  
      @user.fbid=userinfo['id']
      @user.email = userinfo['email']
    else
      @user = current_user
    end
  end
  
  def create
    @user1 = User.new(params[:user])
    if @user1.save
      saveduser = User.find_by_fbid(params[:user][:fbid])
      unless saveduser.nil?
        session[:user] = saveduser
      end
      redirect_to "/members/dashboard"
    else
      puts "error while saving user"
    end  
  end

  def signin
    
    if !session['access_token'].nil?
      @graph = Koala::Facebook::API.new(session["access_token"])
      userinfo =  @graph.get_object("me")
      puts "inside"
      puts userinfo
      fb_id=userinfo['id']
      if fb_id
       userObj = User.find_by_fbid(fb_id.to_s) 
       puts userObj
       puts "------------"
        if userObj.nil?
          redirect_to '/members/filldetails'
        else
           session[:user] = userObj
           current_user= userObj
           redirect_to "/members/dashboard"
        end
      end
    elsif !current_user.nil?
      puts "inside2"
      if session[:new_user] != true
        session[:user] = current_user
        redirect_to "/members/dashboard"
      else
#        @user = current_user
        redirect_to '/members/filldetails'
      end
    else  
      #    this is logout. its a temp solution
    redirect_to '/welcome'

    end
  end
  
  def dashboard
    @checkinarr = Array.new
    if (session["access_token"])
        graph = Koala::Facebook::API.new(session["access_token"])
        checkinlist = graph.get_connections('me','checkins')
        unless checkinlist.nil?
          checkinlist.each do |checkin|
            place = checkin["place"]
            loc = Location.new
            loc.name = place["name"]
            location = place["location"]
            unless location.nil?
              loc.city = location["city"]
              loc.address = location["street"]
              loc.zipcode = location["zip"]
            end
            @checkinarr << loc
          end
        end
    end
    @totalclose = Post.latest_closed
    @totalopen = Post.latest_open
    unless session[:user].nil?
      user = session[:user]
      @isadmin = user.admin
    end
  end
  
  def show
    if !session[:user].nil?
      @user= session[:user]
      openUmvox=@user.posts.where("status=?","Open")
      closeUmvox=@user.posts.where("status=?","Closed")
      @totalopen = openUmvox.size unless openUmvox.nil?
      @totalclosed = closeUmvox.length unless closeUmvox.nil?
    end
  end
  
  def updateprofile
    if  ! params[:user][:id].blank?
       user = User.find(params[:user][:id])
       if user.nil?
         user = User.new
         user.password ="qaumxvo"
       end
    else
      user = User.new
#      not the best way
      user.password ="qaumxvo" 
    end  
    user.firstname=params[:user][:firstname]
     user.username = params[:user][:username]
     user.lastname = params[:user][:lastname]
     user.email = params[:user][:email]
     user.city = params[:user][:city]
     user.state = params[:user][:state]
     user.country = params[:user][:country]
     user.fbid = params[:user][:fbid]
     begin 
      user.save!
      session[:user] = user
     rescue ActiveRecord::RecordNotSaved => e
        user.errors.full_messages
     end
     redirect_to "/members/dashboard"
  end
end
