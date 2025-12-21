class PagesController < ApplicationController
  def landing
    # Redirect logged in users to dashboard
    redirect_to dashboard_path if user_signed_in?
  end

  def dashboard
    authenticate_user!
    
    # Mock Data for Dashboard
    @heart_balance = 120
    
    @live_creators = [
      { id: 1, name: "Priya", handle: "@priyacreates", avatar: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&h=100&fit=crop&crop=face", live: true },
      { id: 2, name: "Arjun", handle: "@arjunfitness", avatar: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop&crop=face", live: true },
      { id: 3, name: "Ananya", handle: "@ananyamusic", avatar: "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=100&h=100&fit=crop&crop=face", live: true }
    ]

    @suggested_creators = [
      { id: 4, name: "Karan", handle: "@karancomedy", avatar: "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=100&h=100&fit=crop&crop=face", live: false },
      { id: 5, name: "Vikram", handle: "@vikramfood", avatar: "https://images.unsplash.com/photo-1522556189639-b150ed9c4330?w=100&h=100&fit=crop&crop=face", live: false },
      { id: 6, name: "Riya", handle: "@riyalifestyle", avatar: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&h=100&fit=crop&crop=face", live: false }
    ]

    @feed_posts = [
      { 
        id: 1, 
        creator: @live_creators[0], 
        timestamp: "2 hours ago", 
        content: "Just finished my morning workout! 💪 Feeling energized.", 
        image: "https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800&fit=crop", 
        likes: 1240, 
        comments: 45,
        locked: false 
      },
      { 
        id: 2, 
        creator: @live_creators[1], 
        timestamp: "4 hours ago", 
        content: "Exclusive behind the scenes from today's shoot! 📸 You won't believe what happened...", 
        image: "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800&fit=crop", 
        likes: 56, 
        comments: 12,
        locked: true,
        unlock_price: 25
      },
      { 
        id: 3, 
        creator: @suggested_creators[0], 
        timestamp: "5 hours ago", 
        content: "New comedy sketch is live! Check it out.", 
        image: "https://images.unsplash.com/photo-1527224857830-43a7acc85260?w=800&fit=crop", 
        likes: 3400, 
        comments: 120,
        locked: false 
      },
      { 
        id: 4, 
        creator: @suggested_creators[2], 
        timestamp: "1 day ago", 
        content: "Secret recipe revealed! 🤫 Only for my true fans.", 
        image: "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800&fit=crop", 
        likes: 89, 
        comments: 5,
        locked: true,
        unlock_price: 50
      },
      { 
        id: 5, 
        creator: @live_creators[2], 
        timestamp: "1 day ago", 
        content: "Studio vibes 🎵 Working on something special.", 
        image: "https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?w=800&fit=crop", 
        likes: 2100, 
        comments: 88,
        locked: true,
        unlock_price: 30
      }
    ]

    @active_chats = [
      { id: 1, creator: @live_creators[0], last_message: "Hey! Thanks for the tip ❤️", time: "10m" },
      { id: 2, creator: @suggested_creators[1], last_message: "New exclusive photo sent!", time: "1h" },
      { id: 3, creator: @live_creators[1], last_message: "See you at the live stream!", time: "2h" },
      { id: 4, creator: @suggested_creators[2], last_message: "Did you like the recipe?", time: "1d" }
    ]
  end

  def privacy_policy
  end

  def terms_of_service
  end

  def content_guidelines
  end

  def creator_terms
  end

  def fan_terms
  end
end
