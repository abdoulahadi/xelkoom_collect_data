import React from 'react';
import {
  Grid,
  Card,
  CardContent,
  Typography,
  Box,
  CircularProgress,
} from '@mui/material';
import {
  People,
  CheckCircle,
  AdminPanelSettings,
  PersonOff,
} from '@mui/icons-material';

interface UserStatsCardsProps {
  totalUsers: number;
  activeUsers: number;
  adminUsers: number;
  inactiveUsers: number;
  loading?: boolean;
}

const UserStatsCards: React.FC<UserStatsCardsProps> = ({
  totalUsers,
  activeUsers,
  adminUsers,
  inactiveUsers,
  loading = false,
}) => {
  const stats = [
    {
      title: 'Total utilisateurs',
      value: totalUsers,
      icon: <People sx={{ fontSize: 40 }} />,
      color: 'primary.main',
      bgColor: 'primary.light',
    },
    {
      title: 'Utilisateurs actifs',
      value: activeUsers,
      icon: <CheckCircle sx={{ fontSize: 40 }} />,
      color: 'success.main',
      bgColor: 'success.light',
    },
    {
      title: 'Administrateurs',
      value: adminUsers,
      icon: <AdminPanelSettings sx={{ fontSize: 40 }} />,
      color: 'error.main',
      bgColor: 'error.light',
    },
    {
      title: 'Utilisateurs inactifs',
      value: inactiveUsers,
      icon: <PersonOff sx={{ fontSize: 40 }} />,
      color: 'warning.main',
      bgColor: 'warning.light',
    },
  ];

  if (loading) {
    return (
      <Grid container spacing={3} sx={{ mb: 3 }}>
        {[1, 2, 3, 4].map((index) => (
          <Grid item xs={12} sm={6} md={3} key={index}>
            <Card>
              <CardContent>
                <Box
                  sx={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    minHeight: 100,
                  }}
                >
                  <CircularProgress />
                </Box>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>
    );
  }

  return (
    <Grid container spacing={3} sx={{ mb: 3 }}>
      {stats.map((stat, index) => (
        <Grid item xs={12} sm={6} md={3} key={index}>
          <Card
            sx={{
              background: `linear-gradient(135deg, ${stat.bgColor}20 0%, ${stat.bgColor}10 100%)`,
              border: `1px solid ${stat.bgColor}40`,
            }}
          >
            <CardContent>
              <Box
                sx={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                }}
              >
                <Box>
                  <Typography variant="h4" fontWeight={700} color={stat.color}>
                    {stat.value.toLocaleString()}
                  </Typography>
                  <Typography
                    variant="body2"
                    color="text.secondary"
                    sx={{ mt: 1 }}
                  >
                    {stat.title}
                  </Typography>
                </Box>
                <Box
                  sx={{
                    p: 1,
                    borderRadius: '50%',
                    backgroundColor: `${stat.bgColor}30`,
                    color: stat.color,
                  }}
                >
                  {stat.icon}
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      ))}
    </Grid>
  );
};

export default UserStatsCards;
