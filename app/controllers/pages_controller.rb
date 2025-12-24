class PagesController < ApplicationController
  def landing
    # Redirect logged in users to dashboard
    redirect_to dashboard_path if user_signed_in?
  end

  def dashboard
    authenticate_user!
    
    # Mock Data for Dashboard
    @heart_balance = 120
    
    # Row 1: Creators Online (Live Now)
    @online_creators = [
      { id: 1, name: "Priya Sharma", handle: "@priyacreates", avatar: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&h=400&fit=crop&crop=face", cover: "https://images.unsplash.com/photo-1519699047748-de8e457a634e?w=600&h=400&fit=crop", category: "Lifestyle", followers: "125K", online: true },
      { id: 2, name: "Arjun Kapoor", handle: "@arjunfitness", avatar: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop&crop=face", cover: "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=600&h=400&fit=crop", category: "Fitness", followers: "89K", online: true },
      { id: 3, name: "Ananya Rao", handle: "@ananyamusic", avatar: "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400&h=400&fit=crop&crop=face", cover: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=600&h=400&fit=crop", category: "Music", followers: "210K", online: true },
      { id: 4, name: "Rahul Dev", handle: "@rahuldev", avatar: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&h=400&fit=crop&crop=face", cover: "https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=600&h=400&fit=crop", category: "Comedy", followers: "156K", online: true },
      { id: 5, name: "Meera Nair", handle: "@meeranair", avatar: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400&h=400&fit=crop&crop=face", cover: "https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=600&h=400&fit=crop", category: "Fashion", followers: "78K", online: true }
    ]
    
    # Row 2: Popular Creators
    @popular_creators = [
      { id: 6, name: "Karan Johar", handle: "@karancomedy", avatar: "https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=400&h=400&fit=crop&crop=face", cover: "https://images.unsplash.com/photo-1527224857830-43a7acc85260?w=600&h=400&fit=crop", category: "Entertainment", followers: "1.2M", online: false },
      { id: 7, name: "Shreya Ghoshal", handle: "@shreyasings", avatar: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&h=400&fit=crop&crop=face", cover: "https://images.unsplash.com/photo-1514320291840-2e0a9bf2a9ae?w=600&h=400&fit=crop", category: "Music", followers: "2.5M", online: false },
      { id: 8, name: "Virat Singh", handle: "@viratfitness", avatar: "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&h=400&fit=crop&crop=face", cover: "https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=600&h=400&fit=crop", category: "Sports", followers: "890K", online: true },
      { id: 9, name: "Deepika Menon", handle: "@deepikacooks", avatar: "https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=400&h=400&fit=crop&crop=face", cover: "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=600&h=400&fit=crop", category: "Food", followers: "567K", online: false },
      { id: 10, name: "Aditya Roy", handle: "@adityatravel", avatar: "https://images.unsplash.com/photo-1522556189639-b150ed9c4330?w=400&h=400&fit=crop&crop=face", cover: "https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?w=600&h=400&fit=crop", category: "Travel", followers: "432K", online: false },
      { id: 11, name: "Nisha Patel", handle: "@nishabeauty", avatar: "https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=400&h=400&fit=crop&crop=face", cover: "https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=600&h=400&fit=crop", category: "Beauty", followers: "678K", online: true }
    ]
    
    # Row 3: Following (empty for new users) / Suggestions
    @following_creators = [] # Empty for demo - show suggestions instead
    
    @suggested_creators = [
      { id: 12, name: "Rohit Sharma", handle: "@rohitgaming", avatar: "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400&h=400&fit=crop&crop=face", cover: "https://images.unsplash.com/photo-1542751371-adc38448a05e?w=600&h=400&fit=crop", category: "Gaming", followers: "345K", online: false },
      { id: 13, name: "Kavya Iyer", handle: "@kavyadance", avatar: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&h=400&fit=crop&crop=face", cover: "https://images.unsplash.com/photo-1518834107812-67b0b7c58434?w=600&h=400&fit=crop", category: "Dance", followers: "234K", online: true },
      { id: 14, name: "Sanjay Mehta", handle: "@sanjaytech", avatar: "https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=400&h=400&fit=crop&crop=face", cover: "https://images.unsplash.com/photo-1518770660439-4636190af475?w=600&h=400&fit=crop", category: "Tech", followers: "189K", online: false },
      { id: 15, name: "Tara Singh", handle: "@tarayoga", avatar: "https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400&h=400&fit=crop&crop=face", cover: "https://images.unsplash.com/photo-1545389336-cf090694435e?w=600&h=400&fit=crop", category: "Wellness", followers: "156K", online: false },
      { id: 16, name: "Aman Gupta", handle: "@amanstartup", avatar: "https://images.unsplash.com/photo-1560250097-0b93528c311a?w=400&h=400&fit=crop&crop=face", cover: "https://images.unsplash.com/photo-1559136555-9303baea8ebd?w=600&h=400&fit=crop", category: "Business", followers: "412K", online: true }
    ]
    
    # Active chats for messages
    @active_chats = [
      { id: 1, creator: @online_creators[0], last_message: "Hey! Thanks for the tip ❤️", time: "10m" },
      { id: 2, creator: @popular_creators[1], last_message: "New exclusive photo sent!", time: "1h" },
      { id: 3, creator: @online_creators[1], last_message: "See you at the live stream!", time: "2h" }
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
