import React, { createContext, useState, useContext } from 'react';

const AuthContext = createContext();

const LOCAL_USER = {
  id: 'local-user',
  email: 'local@omega.app',
  full_name: 'Local User',
};

export const AuthProvider = ({ children }) => {
  const [user] = useState(LOCAL_USER);
  const [isAuthenticated] = useState(true);
  const [isLoadingAuth] = useState(false);
  const [isLoadingPublicSettings] = useState(false);
  const [authError] = useState(null);
  const [authChecked] = useState(true);
  const [appPublicSettings] = useState(null);

  const logout = () => {
    // no-op: local mode has no session to clear
  };

  const navigateToLogin = () => {
    // no-op: local mode never requires login
  };

  const checkUserAuth = async () => user;
  const checkAppState = async () => {};

  return (
    <AuthContext.Provider value={{
      user,
      isAuthenticated,
      isLoadingAuth,
      isLoadingPublicSettings,
      authError,
      appPublicSettings,
      authChecked,
      logout,
      navigateToLogin,
      checkUserAuth,
      checkAppState
    }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
