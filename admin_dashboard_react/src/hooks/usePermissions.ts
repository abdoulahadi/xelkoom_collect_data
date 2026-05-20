import { useAuth } from '../contexts/AuthContext';

export const usePermissions = () => {
  const { user } = useAuth();

  const isAdmin = user?.role === 'admin';
  const isModerator = user?.role === 'moderator';
  const isUser = user?.role === 'user';

  const canManageUsers = isAdmin;
  const canModerateSentences = isAdmin || isModerator;
  const canModerateRecordings = isAdmin || isModerator;
  const canViewAnalytics = isAdmin || isModerator;
  const canExportData = isAdmin || isModerator;
  const canManageSystem = isAdmin;

  // Permissions génériques pour CRUD
  const canEdit = isAdmin || isModerator;
  const canDelete = isAdmin;
  const canCreate = isAdmin || isModerator;
  const canView = isAdmin || isModerator;

  return {
    user,
    isAdmin,
    isModerator,
    isUser,
    canManageUsers,
    canModerateSentences,
    canModerateRecordings,
    canViewAnalytics,
    canExportData,
    canManageSystem,
    canEdit,
    canDelete,
    canCreate,
    canView,
  };
};
