// Turbo Cleanup Manager
// Handles proper cleanup of event listeners and subscriptions when navigating with Turbo

class TurboCleanupManager {
  constructor() {
    this.cleanupCallbacks = [];
    this.initialized = false;
    
    this.init();
  }

  init() {
    if (this.initialized) return;
    this.initialized = true;

    // Clean up before Turbo navigates away
    document.addEventListener('turbo:before-cache', () => {
      this.runCleanup();
    });

    // Clean up before a new page render
    document.addEventListener('turbo:before-render', () => {
      this.runCleanup();
    });

    // Reinitialize on page load
    document.addEventListener('turbo:load', () => {
      this.initializePageComponents();
    });

    // Also handle initial page load
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', () => {
        this.initializePageComponents();
      });
    } else {
      this.initializePageComponents();
    }
  }

  // Register a cleanup callback for the current page
  onCleanup(callback) {
    if (typeof callback === 'function') {
      this.cleanupCallbacks.push(callback);
    }
  }

  // Run all cleanup callbacks
  runCleanup() {
    this.cleanupCallbacks.forEach(callback => {
      try {
        callback();
      } catch (error) {
        console.error('Cleanup error:', error);
      }
    });
    this.cleanupCallbacks = [];
  }

  // Initialize common page components
  initializePageComponents() {
    this.initUserMenu();
  }

  // User menu initialization - used across all dashboard pages
  initUserMenu() {
    const userMenuBtn = document.getElementById('user-menu-btn');
    const userMenuDropdown = document.getElementById('user-menu-dropdown');

    if (!userMenuBtn || !userMenuDropdown) return;

    // Remove any existing listeners by cloning and replacing
    const newBtn = userMenuBtn.cloneNode(true);
    userMenuBtn.parentNode.replaceChild(newBtn, userMenuBtn);

    // Handler for toggling dropdown
    const toggleHandler = (e) => {
      e.stopPropagation();
      userMenuDropdown.classList.toggle('hidden');
    };

    // Handler for closing dropdown on outside click
    const closeHandler = (e) => {
      if (!userMenuDropdown.contains(e.target) && !newBtn.contains(e.target)) {
        userMenuDropdown.classList.add('hidden');
      }
    };

    newBtn.addEventListener('click', toggleHandler);
    document.addEventListener('click', closeHandler);

    // Register cleanup
    this.onCleanup(() => {
      document.removeEventListener('click', closeHandler);
    });
  }
}

// Create global instance
window.TurboCleanup = new TurboCleanupManager();

export default window.TurboCleanup;

