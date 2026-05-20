import React from 'react';
import {
  Box,
  Typography,
  Breadcrumbs,
  Link,
  Container,
} from '@mui/material';
import {
  Home as HomeIcon,
  Balance as BalanceIcon,
} from '@mui/icons-material';
import { Link as RouterLink } from 'react-router-dom';
import BalanceDashboard from '../components/BalanceDashboard';

const BalancePage: React.FC = () => {
  return (
    <Container maxWidth="xl">
      <Box sx={{ py: 3 }}>
        {/* Breadcrumbs */}
        <Breadcrumbs sx={{ mb: 3 }}>
          <Link
            component={RouterLink}
            to="/dashboard"
            underline="hover"
            sx={{ display: 'flex', alignItems: 'center' }}
          >
            <HomeIcon sx={{ mr: 0.5 }} fontSize="inherit" />
            Dashboard
          </Link>
          <Typography
            sx={{ display: 'flex', alignItems: 'center' }}
            color="text.primary"
          >
            <BalanceIcon sx={{ mr: 0.5 }} fontSize="inherit" />
            Équilibrage des Enregistrements
          </Typography>
        </Breadcrumbs>

        {/* Header */}
        <Box sx={{ mb: 4 }}>
          <Typography variant="h4" component="h1" gutterBottom>
            Équilibrage des Enregistrements
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Analyse et monitoring de la distribution des enregistrements par phrase pour optimiser la qualité du dataset TTS.
          </Typography>
        </Box>

        {/* Balance Dashboard */}
        <BalanceDashboard />
      </Box>
    </Container>
  );
};

export default BalancePage;
