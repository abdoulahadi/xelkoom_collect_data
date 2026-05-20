import React, { useState } from 'react';
import {
  Card,
  CardContent,
  CardHeader,
  Typography,
  Box,
  Chip,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TablePagination,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Alert,
  LinearProgress,
} from '@mui/material';
import {
  Info,
  Warning,
  Error as ErrorIcon,
  BugReport,
} from '@mui/icons-material';
import { SystemLog, PaginatedResponse } from '../types';

interface SystemLogsCardProps {
  logs: PaginatedResponse<SystemLog> | null;
  loading?: boolean;
  onPageChange: (page: number) => void;
  onLevelFilter: (level: string | undefined) => void;
}

const SystemLogsCard: React.FC<SystemLogsCardProps> = ({
  logs,
  loading = false,
  onPageChange,
  onLevelFilter,
}) => {
  const [selectedLevel, setSelectedLevel] = useState<string>('');

  const getLevelIcon = (level: string) => {
    switch (level) {
      case 'INFO':
        return <Info color="info" fontSize="small" />;
      case 'WARNING':
        return <Warning color="warning" fontSize="small" />;
      case 'ERROR':
        return <ErrorIcon color="error" fontSize="small" />;
      case 'DEBUG':
        return <BugReport color="action" fontSize="small" />;
      default:
        return <Info color="disabled" fontSize="small" />;
    }
  };

  const getLevelColor = (level: string) => {
    switch (level) {
      case 'INFO':
        return 'info' as const;
      case 'WARNING':
        return 'warning' as const;
      case 'ERROR':
        return 'error' as const;
      case 'DEBUG':
        return 'default' as const;
      default:
        return 'default' as const;
    }
  };

  const handleLevelChange = (level: string) => {
    setSelectedLevel(level);
    onLevelFilter(level || undefined);
  };

  const handlePageChange = (_: unknown, page: number) => {
    onPageChange(page + 1); // MUI uses 0-based pagination, backend uses 1-based
  };

  return (
    <Card>
      <CardHeader
        title="Logs système"
        action={
          <FormControl size="small" sx={{ minWidth: 120 }}>
            <InputLabel>Niveau</InputLabel>
            <Select
              value={selectedLevel}
              label="Niveau"
              onChange={(e) => handleLevelChange(e.target.value)}
            >
              <MenuItem value="">Tous</MenuItem>
              <MenuItem value="ERROR">Erreur</MenuItem>
              <MenuItem value="WARNING">Avertissement</MenuItem>
              <MenuItem value="INFO">Info</MenuItem>
              <MenuItem value="DEBUG">Debug</MenuItem>
            </Select>
          </FormControl>
        }
      />
      <CardContent>
        {loading && <LinearProgress sx={{ mb: 2 }} />}
        
        {!loading && !logs && (
          <Alert severity="error">
            Impossible de charger les logs système
          </Alert>
        )}

        {!loading && logs && logs.items.length === 0 && (
          <Alert severity="info">
            Aucun log disponible pour le niveau sélectionné
          </Alert>
        )}

        {!loading && logs && logs.items.length > 0 && (
          <>
            <TableContainer>
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell>Timestamp</TableCell>
                    <TableCell>Niveau</TableCell>
                    <TableCell>Module</TableCell>
                    <TableCell>Message</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {logs.items.map((log, index) => (
                    <TableRow key={index} hover>
                      <TableCell>
                        <Typography variant="body2" component="span">
                          {new Date(log.timestamp).toLocaleString('fr-FR')}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                          {getLevelIcon(log.level)}
                          <Chip
                            label={log.level}
                            color={getLevelColor(log.level)}
                            size="small"
                            variant="outlined"
                          />
                        </Box>
                      </TableCell>
                      <TableCell>
                        <Typography variant="body2" color="text.secondary">
                          {log.module}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Typography variant="body2">
                          {log.message}
                        </Typography>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>

            <TablePagination
              component="div"
              count={logs.total}
              page={logs.page - 1} // Convert to 0-based for MUI
              onPageChange={handlePageChange}
              rowsPerPage={logs.size}
              rowsPerPageOptions={[25, 50, 100]}
              onRowsPerPageChange={() => {}} // Could implement if needed
              labelDisplayedRows={({ from, to, count }) =>
                `${from}-${to} sur ${count !== -1 ? count : `plus de ${to}`}`
              }
              labelRowsPerPage="Lignes par page:"
            />
          </>
        )}
      </CardContent>
    </Card>
  );
};

export default SystemLogsCard;
