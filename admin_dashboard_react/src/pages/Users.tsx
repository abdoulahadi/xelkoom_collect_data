import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TablePagination,
  Chip,
  IconButton,
  Button,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  DialogContentText,
  Menu,
  ListItemIcon,
  ListItemText,
  Alert,
  CircularProgress,
  Tooltip,
  Card,
  CardContent,
  Grid,
} from '@mui/material';
import {
  MoreVert,
  Edit,
  Block,
  CheckCircle,
  Delete,
  Search,
  Download,
  AdminPanelSettings,
  SupervisorAccount,
  Person,
  PersonAdd,
} from '@mui/icons-material';
import { User, UserFilters } from '../types';
import { apiService } from '../services/api';
import { getErrorMessage } from '../services/errorUtils';
import { usePermissions } from '../hooks/usePermissions';
import CreateUserDialog from '../components/CreateUserDialog';
import UserStatsCards from '../components/UserStatsCards';

interface UserDetailsDialogProps {
  user: User | null;
  open: boolean;
  onClose: () => void;
  onUserUpdate: (user: User) => void;
}

const UserDetailsDialog: React.FC<UserDetailsDialogProps> = ({
  user,
  open,
  onClose,
  onUserUpdate,
}) => {
  const [loading, setLoading] = useState(false);
  const [editMode, setEditMode] = useState(false);
  const [formData, setFormData] = useState<Partial<User>>({});

  useEffect(() => {
    if (user) {
      setFormData({
        is_admin: user.is_admin,
        is_active: user.is_active,
        role: user.role,
      });
    }
  }, [user]);

  const handleSave = async () => {
    if (!user) return;
    
    setLoading(true);
    try {
      const updatedUser = await apiService.updateUser(user.id.toString(), formData);
      onUserUpdate(updatedUser);
      setEditMode(false);
    } catch (error) {
      console.error('Erreur lors de la mise à jour:', error);
    } finally {
      setLoading(false);
    }
  };

  if (!user) return null;

  return (
    <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth>
      <DialogTitle>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <Person />
          Détails de l'utilisateur
        </Box>
      </DialogTitle>
      <DialogContent>
        <Grid container spacing={3} sx={{ mt: 1 }}>
          <Grid item xs={12} md={6}>
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  Informations personnelles
                </Typography>
                <Box sx={{ mb: 2 }}>
                  <Typography variant="body2" color="text.secondary">
                    Nom d'utilisateur
                  </Typography>
                  <Typography variant="body1" fontWeight={500}>
                    {user.username}
                  </Typography>
                </Box>
                <Box sx={{ mb: 2 }}>
                  <Typography variant="body2" color="text.secondary">
                    Genre
                  </Typography>
                  <Typography variant="body1" fontWeight={500}>
                    {user.gender === 'male' ? 'Homme' : user.gender === 'female' ? 'Femme' : 'Autre'}
                  </Typography>
                </Box>
                <Box sx={{ mb: 2 }}>
                  <Typography variant="body2" color="text.secondary">
                    Tranche d'âge
                  </Typography>
                  <Typography variant="body1" fontWeight={500}>
                    {user.age_range}
                  </Typography>
                </Box>
                <Box sx={{ mb: 2 }}>
                  <Typography variant="body2" color="text.secondary">
                    Date d'inscription
                  </Typography>
                  <Typography variant="body1" fontWeight={500}>
                    {new Date(user.created_at).toLocaleDateString('fr-FR')}
                  </Typography>
                </Box>
              </CardContent>
            </Card>
          </Grid>
          
          <Grid item xs={12} md={6}>
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  Statistiques
                </Typography>
                <Box sx={{ mb: 2 }}>
                  <Typography variant="body2" color="text.secondary">
                    Enregistrements totaux
                  </Typography>
                  <Typography variant="h4" color="primary">
                    {user.recording_count}
                  </Typography>
                </Box>
                <Box sx={{ mb: 2 }}>
                  <Typography variant="body2" color="text.secondary">
                    Enregistrements validés
                  </Typography>
                  <Typography variant="h4" color="success.main">
                    {user.validated_recordings}
                  </Typography>
                </Box>
                <Box sx={{ mb: 2 }}>
                  <Typography variant="body2" color="text.secondary">
                    Taux de validation
                  </Typography>
                  <Typography variant="h4" color="info.main">
                    {user.recording_count > 0 
                      ? `${Math.round((user.validated_recordings / user.recording_count) * 100)}%`
                      : '0%'
                    }
                  </Typography>
                </Box>
              </CardContent>
            </Card>
          </Grid>

          <Grid item xs={12}>
            <Card>
              <CardContent>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                  <Typography variant="h6">
                    Paramètres du compte
                  </Typography>
                  {!editMode && (
                    <Button
                      startIcon={<Edit />}
                      onClick={() => setEditMode(true)}
                      variant="outlined"
                      size="small"
                    >
                      Modifier
                    </Button>
                  )}
                </Box>

                {editMode ? (
                  <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                    <FormControl fullWidth>
                      <InputLabel>Rôle</InputLabel>
                      <Select
                        value={formData.role || 'user'}
                        onChange={(e) => setFormData({ ...formData, role: e.target.value as User['role'] })}
                        label="Rôle"
                      >
                        <MenuItem value="user">Utilisateur</MenuItem>
                        <MenuItem value="moderator">Modérateur</MenuItem>
                        <MenuItem value="admin">Administrateur</MenuItem>
                      </Select>
                    </FormControl>

                    <FormControl fullWidth>
                      <InputLabel>Statut</InputLabel>
                      <Select
                        value={formData.is_active ? 'active' : 'inactive'}
                        onChange={(e) => setFormData({ ...formData, is_active: e.target.value === 'active' })}
                        label="Statut"
                      >
                        <MenuItem value="active">Actif</MenuItem>
                        <MenuItem value="inactive">Inactif</MenuItem>
                      </Select>
                    </FormControl>

                    <Box sx={{ display: 'flex', gap: 2, justifyContent: 'flex-end' }}>
                      <Button
                        onClick={() => {
                          setEditMode(false);
                          setFormData({
                            is_admin: user.is_admin,
                            is_active: user.is_active,
                            role: user.role,
                          });
                        }}
                        disabled={loading}
                      >
                        Annuler
                      </Button>
                      <Button
                        variant="contained"
                        onClick={handleSave}
                        disabled={loading}
                      >
                        {loading ? <CircularProgress size={20} /> : 'Sauvegarder'}
                      </Button>
                    </Box>
                  </Box>
                ) : (
                  <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                    <Box>
                      <Typography variant="body2" color="text.secondary">
                        Rôle
                      </Typography>
                      <Chip
                        icon={user.role === 'admin' ? <AdminPanelSettings /> : 
                              user.role === 'moderator' ? <SupervisorAccount /> : <Person />}
                        label={user.role === 'admin' ? 'Administrateur' : 
                               user.role === 'moderator' ? 'Modérateur' : 'Utilisateur'}
                        color={user.role === 'admin' ? 'error' : 
                               user.role === 'moderator' ? 'warning' : 'default'}
                        variant="outlined"
                      />
                    </Box>
                    <Box>
                      <Typography variant="body2" color="text.secondary">
                        Statut du compte
                      </Typography>
                      <Chip
                        icon={user.is_active ? <CheckCircle /> : <Block />}
                        label={user.is_active ? 'Actif' : 'Inactif'}
                        color={user.is_active ? 'success' : 'error'}
                        variant="outlined"
                      />
                    </Box>
                    <Box>
                      <Typography variant="body2" color="text.secondary">
                        Consentement RGPD
                      </Typography>
                      <Chip
                        icon={user.consent_given ? <CheckCircle /> : <Block />}
                        label={user.consent_given ? 'Donné' : 'Non donné'}
                        color={user.consent_given ? 'success' : 'error'}
                        variant="outlined"
                      />
                    </Box>
                  </Box>
                )}
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Fermer</Button>
      </DialogActions>
    </Dialog>
  );
};

const Users: React.FC = () => {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(25);
  const [total, setTotal] = useState(0);
  const [activeUsersCount, setActiveUsersCount] = useState(0);
  const [adminUsersCount, setAdminUsersCount] = useState(0);
  const [inactiveUsersCount, setInactiveUsersCount] = useState(0);
  const [searchTerm, setSearchTerm] = useState('');
  const [filters, setFilters] = useState<UserFilters>({});
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [userDetailsOpen, setUserDetailsOpen] = useState(false);
  const [actionMenuAnchor, setActionMenuAnchor] = useState<null | HTMLElement>(null);
  const [actionUser, setActionUser] = useState<User | null>(null);
  const [confirmDialog, setConfirmDialog] = useState<{
    open: boolean;
    title: string;
    message: string;
    action: () => void;
  }>({
    open: false,
    title: '',
    message: '',
    action: () => {},
  });
  const [createUserOpen, setCreateUserOpen] = useState(false);

  const { canManageUsers } = usePermissions();

  // Vérifier les permissions
  if (!canManageUsers) {
    return (
      <Box sx={{ p: 3 }}>
        <Alert severity="error">
          Vous n'avez pas les permissions nécessaires pour gérer les utilisateurs.
        </Alert>
      </Box>
    );
  }

  const loadUsers = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await apiService.getUsers(filters, page + 1, rowsPerPage);
      setUsers(response.items);
      setTotal(response.total);
      setActiveUsersCount(response.active_users);
      setAdminUsersCount(response.admin_users);
      setInactiveUsersCount(response.inactive_users);
    } catch (err: unknown) {
      setError(getErrorMessage(err, 'Erreur lors du chargement des utilisateurs'));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadUsers();
  }, [page, rowsPerPage, filters]);

  // Debounce search — server-side
  useEffect(() => {
    const timeoutId = setTimeout(() => {
      setFilters(prev => ({ ...prev, search: searchTerm || undefined }));
      setPage(0);
    }, 300);

    return () => clearTimeout(timeoutId);
  }, [searchTerm]);

  const handleChangePage = (_event: unknown, newPage: number) => {
    setPage(newPage);
  };

  const handleChangeRowsPerPage = (event: React.ChangeEvent<HTMLInputElement>) => {
    setRowsPerPage(parseInt(event.target.value, 10));
    setPage(0);
  };

  const handleOpenActionMenu = (event: React.MouseEvent<HTMLElement>, user: User) => {
    setActionMenuAnchor(event.currentTarget);
    setActionUser(user);
  };

  const handleCloseActionMenu = () => {
    setActionMenuAnchor(null);
    setActionUser(null);
  };

  const handleViewUser = (user: User) => {
    setSelectedUser(user);
    setUserDetailsOpen(true);
    handleCloseActionMenu();
  };

  const handleToggleUserStatus = async (user: User) => {
    try {
      const updatedUser = user.is_active 
        ? await apiService.deactivateUser(user.id.toString())
        : await apiService.activateUser(user.id.toString());
      
      setUsers(users.map(u => u.id === user.id ? { ...u, is_active: updatedUser.is_active } : u));
      handleCloseActionMenu();
    } catch (err: unknown) {
      setError(getErrorMessage(err, 'Erreur lors de la modification du statut'));
    }
  };

  const handleDeleteUser = async (user: User) => {
    setConfirmDialog({
      open: true,
      title: 'Supprimer l\'utilisateur',
      message: `Êtes-vous sûr de vouloir supprimer l'utilisateur "${user.username}" ? Cette action est irréversible.`,
      action: async () => {
        try {
          await apiService.deleteUser(user.id.toString());
          await loadUsers(); // Reload users list
          setConfirmDialog({ ...confirmDialog, open: false });
        } catch (err: unknown) {
          setError(getErrorMessage(err, 'Erreur lors de la suppression'));
        }
      }
    });
    handleCloseActionMenu();
  };

  const handleUserUpdate = (updatedUser: User) => {
    setUsers(users.map(u => u.id === updatedUser.id ? updatedUser : u));
    setSelectedUser(updatedUser);
  };

  const handleUserCreated = (newUser: User) => {
    setUsers([newUser, ...users]);
    setCreateUserOpen(false);
  };

  const getRoleIcon = (role: string) => {
    switch (role) {
      case 'admin':
        return <AdminPanelSettings />;
      case 'moderator':
        return <SupervisorAccount />;
      default:
        return <Person />;
    }
  };

  const getRoleColor = (role: string): 'error' | 'warning' | 'default' => {
    switch (role) {
      case 'admin':
        return 'error';
      case 'moderator':
        return 'warning';
      default:
        return 'default';
    }
  };

  const getRoleLabel = (role: string) => {
    switch (role) {
      case 'admin':
        return 'Administrateur';
      case 'moderator':
        return 'Modérateur';
      default:
        return 'Utilisateur';
    }
  };

  const exportUsers = async () => {
    try {
      const blob = await apiService.exportUsers('csv');
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `users-${new Date().toISOString().split('T')[0]}.csv`;
      document.body.appendChild(a);
      a.click();
      window.URL.revokeObjectURL(url);
      document.body.removeChild(a);
    } catch (err: unknown) {
      setError('Erreur lors de l\'export des utilisateurs');
    }
  };

  return (
    <Box sx={{ p: 3 }}>
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" fontWeight={700} gutterBottom>
          Gestion des utilisateurs
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Administration des comptes utilisateurs
        </Typography>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 3 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      {/* Statistiques des utilisateurs */}
      <UserStatsCards
        totalUsers={total}
        activeUsers={activeUsersCount}
        adminUsers={adminUsersCount}
        inactiveUsers={inactiveUsersCount}
        loading={loading}
      />

      {/* Barre d'outils */}
      <Paper sx={{ p: 2, mb: 3 }}>
        <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap', alignItems: 'center' }}>
          <TextField
            placeholder="Rechercher un utilisateur..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            size="small"
            sx={{ minWidth: 250 }}
            InputProps={{
              startAdornment: <Search sx={{ mr: 1, color: 'text.secondary' }} />,
            }}
          />
          
          <FormControl size="small" sx={{ minWidth: 120 }}>
            <InputLabel>Statut</InputLabel>
            <Select
              value={filters.is_active === undefined ? '' : filters.is_active ? 'active' : 'inactive'}
              onChange={(e) => setFilters({
                ...filters,
                is_active: e.target.value === '' ? undefined : e.target.value === 'active'
              })}
              label="Statut"
            >
              <MenuItem value="">Tous</MenuItem>
              <MenuItem value="active">Actif</MenuItem>
              <MenuItem value="inactive">Inactif</MenuItem>
            </Select>
          </FormControl>

          <FormControl size="small" sx={{ minWidth: 120 }}>
            <InputLabel>Rôle</InputLabel>
            <Select
              value={filters.is_admin === undefined ? '' : filters.is_admin ? 'admin' : 'user'}
              onChange={(e) => setFilters({
                ...filters,
                is_admin: e.target.value === '' ? undefined : e.target.value === 'admin'
              })}
              label="Rôle"
            >
              <MenuItem value="">Tous</MenuItem>
              <MenuItem value="admin">Admin</MenuItem>
              <MenuItem value="user">Utilisateur</MenuItem>
            </Select>
          </FormControl>

          <Button
            variant="contained"
            startIcon={<PersonAdd />}
            onClick={() => setCreateUserOpen(true)}
          >
            Ajouter un utilisateur
          </Button>

          <Button
            variant="outlined"
            startIcon={<Download />}
            onClick={exportUsers}
          >
            Exporter
          </Button>
        </Box>
      </Paper>

      {/* Tableau des utilisateurs */}
      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Utilisateur</TableCell>
              <TableCell>Genre</TableCell>
              <TableCell>Âge</TableCell>
              <TableCell>Rôle</TableCell>
              <TableCell>Statut</TableCell>
              <TableCell>Enregistrements</TableCell>
              <TableCell>Validation</TableCell>
              <TableCell>Inscription</TableCell>
              <TableCell align="right">Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {loading ? (
              <TableRow>
                <TableCell colSpan={9} align="center" sx={{ py: 4 }}>
                  <CircularProgress />
                </TableCell>
              </TableRow>
            ) : users.length === 0 ? (
              <TableRow>
                <TableCell colSpan={9} align="center" sx={{ py: 4 }}>
                  <Typography color="text.secondary">
                    Aucun utilisateur trouvé
                  </Typography>
                </TableCell>
              </TableRow>
            ) : (
              users.map((user) => (
                <TableRow key={user.id} hover>
                  <TableCell>
                    <Box>
                      <Typography variant="body2" fontWeight={500}>
                        {user.username}
                      </Typography>
                      <Typography variant="caption" color="text.secondary">
                        ID: {user.id}
                      </Typography>
                    </Box>
                  </TableCell>
                  <TableCell>
                    {user.gender === 'male' ? 'Homme' : user.gender === 'female' ? 'Femme' : 'Autre'}
                  </TableCell>
                  <TableCell>{user.age_range}</TableCell>
                  <TableCell>
                    <Chip
                      icon={getRoleIcon(user.role)}
                      label={getRoleLabel(user.role)}
                      color={getRoleColor(user.role)}
                      size="small"
                      variant="outlined"
                    />
                  </TableCell>
                  <TableCell>
                    <Chip
                      icon={user.is_active ? <CheckCircle /> : <Block />}
                      label={user.is_active ? 'Actif' : 'Inactif'}
                      color={user.is_active ? 'success' : 'error'}
                      size="small"
                      variant="outlined"
                    />
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2" fontWeight={500}>
                      {user.recording_count}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2" fontWeight={500} color="success.main">
                      {user.validated_recordings}
                    </Typography>
                    {user.recording_count > 0 && (
                      <Typography variant="caption" color="text.secondary">
                        {` (${Math.round((user.validated_recordings / user.recording_count) * 100)}%)`}
                      </Typography>
                    )}
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2">
                      {new Date(user.created_at).toLocaleDateString('fr-FR')}
                    </Typography>
                  </TableCell>
                  <TableCell align="right">
                    <Tooltip title="Actions">
                      <IconButton
                        onClick={(e) => handleOpenActionMenu(e, user)}
                        size="small"
                      >
                        <MoreVert />
                      </IconButton>
                    </Tooltip>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
        
        <TablePagination
          rowsPerPageOptions={[10, 25, 50, 100]}
          component="div"
          count={total}
          rowsPerPage={rowsPerPage}
          page={page}
          onPageChange={handleChangePage}
          onRowsPerPageChange={handleChangeRowsPerPage}
          labelRowsPerPage="Lignes par page:"
          labelDisplayedRows={({ from, to, count }) => 
            `${from}-${to} sur ${count !== -1 ? count : `plus de ${to}`}`
          }
        />
      </TableContainer>

      {/* Menu contextuel */}
      <Menu
        anchorEl={actionMenuAnchor}
        open={Boolean(actionMenuAnchor)}
        onClose={handleCloseActionMenu}
        transformOrigin={{ horizontal: 'right', vertical: 'top' }}
        anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
      >
        <MenuItem onClick={() => actionUser && handleViewUser(actionUser)}>
          <ListItemIcon>
            <Edit fontSize="small" />
          </ListItemIcon>
          <ListItemText>Voir/Modifier</ListItemText>
        </MenuItem>
        <MenuItem onClick={() => actionUser && handleToggleUserStatus(actionUser)}>
          <ListItemIcon>
            {actionUser?.is_active ? <Block fontSize="small" /> : <CheckCircle fontSize="small" />}
          </ListItemIcon>
          <ListItemText>
            {actionUser?.is_active ? 'Désactiver' : 'Activer'}
          </ListItemText>
        </MenuItem>
        <MenuItem 
          onClick={() => actionUser && handleDeleteUser(actionUser)}
          sx={{ color: 'error.main' }}
        >
          <ListItemIcon>
            <Delete fontSize="small" color="error" />
          </ListItemIcon>
          <ListItemText>Supprimer</ListItemText>
        </MenuItem>
      </Menu>

      {/* Dialog de détails utilisateur */}
      <UserDetailsDialog
        user={selectedUser}
        open={userDetailsOpen}
        onClose={() => setUserDetailsOpen(false)}
        onUserUpdate={handleUserUpdate}
      />

      {/* Dialog de confirmation */}
      <Dialog
        open={confirmDialog.open}
        onClose={() => setConfirmDialog({ ...confirmDialog, open: false })}
      >
        <DialogTitle>{confirmDialog.title}</DialogTitle>
        <DialogContent>
          <DialogContentText>{confirmDialog.message}</DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setConfirmDialog({ ...confirmDialog, open: false })}>
            Annuler
          </Button>
          <Button onClick={confirmDialog.action} color="error" variant="contained">
            Confirmer
          </Button>
        </DialogActions>
      </Dialog>

      {/* Dialog de création d'utilisateur */}
      <CreateUserDialog
        open={createUserOpen}
        onClose={() => setCreateUserOpen(false)}
        onUserCreated={handleUserCreated}
      />
    </Box>
  );
};

export default Users;
