// Desktop Notification Service for Flikk
// Handles browser notifications and notification sounds

class FlikkNotifications {
  constructor() {
    this.permission = Notification.permission;
    this.audioContext = null;
    this.isTabVisible = !document.hidden;
    this.soundEnabled = localStorage.getItem('flikk_sound_enabled') !== 'false';
    
    // Listen for visibility changes
    document.addEventListener('visibilitychange', () => {
      this.isTabVisible = !document.hidden;
    });
  }

  // Request notification permission
  async requestPermission() {
    if (!('Notification' in window)) {
      console.log('This browser does not support notifications');
      return false;
    }

    if (this.permission === 'granted') {
      return true;
    }

    if (this.permission !== 'denied') {
      const result = await Notification.requestPermission();
      this.permission = result;
      return result === 'granted';
    }

    return false;
  }

  // Create and play notification sound
  playNotificationSound() {
    if (!this.soundEnabled) return;

    try {
      // Create AudioContext on demand (browsers require user interaction first)
      if (!this.audioContext) {
        this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
      }

      // Resume context if suspended
      if (this.audioContext.state === 'suspended') {
        this.audioContext.resume();
      }

      // Create a pleasant notification sound (similar to FB/Messenger)
      const oscillator = this.audioContext.createOscillator();
      const gainNode = this.audioContext.createGain();

      oscillator.connect(gainNode);
      gainNode.connect(this.audioContext.destination);

      // Two-tone notification (like a soft "ding-dong")
      oscillator.type = 'sine';
      oscillator.frequency.setValueAtTime(830, this.audioContext.currentTime); // First tone (G#5)
      oscillator.frequency.setValueAtTime(622, this.audioContext.currentTime + 0.1); // Second tone (D#5)

      // Fade in and out
      gainNode.gain.setValueAtTime(0, this.audioContext.currentTime);
      gainNode.gain.linearRampToValueAtTime(0.3, this.audioContext.currentTime + 0.02);
      gainNode.gain.linearRampToValueAtTime(0.2, this.audioContext.currentTime + 0.1);
      gainNode.gain.linearRampToValueAtTime(0.25, this.audioContext.currentTime + 0.12);
      gainNode.gain.linearRampToValueAtTime(0, this.audioContext.currentTime + 0.3);

      oscillator.start(this.audioContext.currentTime);
      oscillator.stop(this.audioContext.currentTime + 0.3);
    } catch (error) {
      console.log('Could not play notification sound:', error);
    }
  }

  // Show desktop notification
  showNotification(title, options = {}) {
    // Only show notification if tab is not visible
    if (this.isTabVisible) {
      return null;
    }

    if (this.permission !== 'granted') {
      return null;
    }

    const defaultOptions = {
      icon: '/favicon.svg',
      badge: '/favicon.svg',
      tag: 'flikk-message', // Prevents duplicate notifications
      renotify: true, // Still vibrate for repeated tags
      requireInteraction: false,
      silent: true, // We'll play our own sound
      ...options
    };

    try {
      const notification = new Notification(title, defaultOptions);

      // Play sound
      this.playNotificationSound();

      // Auto-close after 5 seconds
      setTimeout(() => {
        notification.close();
      }, 5000);

      // Handle click - focus the tab
      notification.onclick = () => {
        window.focus();
        notification.close();
        if (options.url) {
          window.location.href = options.url;
        }
      };

      return notification;
    } catch (error) {
      console.error('Error showing notification:', error);
      return null;
    }
  }

  // New message notification
  notifyNewMessage(senderName, messagePreview, conversationUrl) {
    this.showNotification(`New message from ${senderName}`, {
      body: messagePreview,
      tag: `flikk-message-${Date.now()}`,
      url: conversationUrl
    });
  }

  // Toggle sound
  toggleSound(enabled) {
    this.soundEnabled = enabled;
    localStorage.setItem('flikk_sound_enabled', enabled.toString());
    
    if (enabled) {
      // Play a test sound
      this.playNotificationSound();
    }
  }

  // Check if sound is enabled
  isSoundEnabled() {
    return this.soundEnabled;
  }
}

// Create global instance
window.FlikkNotifications = new FlikkNotifications();

// Export for module use
export default window.FlikkNotifications;

