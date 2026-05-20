import React from 'react';
import {
  Card,
  CardContent,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Box,
  Typography,
  SelectChangeEvent,
} from '@mui/material';

export type PeriodFilter = '7d' | '30d' | '90d' | 'all';

interface PeriodFilterProps {
  value: PeriodFilter;
  onChange: (period: PeriodFilter) => void;
  disabled?: boolean;
}

const PeriodFilter: React.FC<PeriodFilterProps> = ({ value, onChange, disabled = false }) => {
  const handleChange = (event: SelectChangeEvent) => {
    onChange(event.target.value as PeriodFilter);
  };

  const periodOptions = [
    { value: '7d', label: '7 derniers jours' },
    { value: '30d', label: '30 derniers jours' },
    { value: '90d', label: '90 derniers jours' },
    { value: 'all', label: 'Toutes les données' },
  ];

  return (
    <Card sx={{ mb: 3 }}>
      <CardContent sx={{ py: 2 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
          <Typography variant="h6" sx={{ fontWeight: 600 }}>
            Période d'analyse
          </Typography>
          <FormControl size="small" sx={{ minWidth: 180 }}>
            <InputLabel id="period-filter-label">Période</InputLabel>
            <Select
              labelId="period-filter-label"
              id="period-filter-select"
              value={value}
              label="Période"
              onChange={handleChange}
              disabled={disabled}
            >
              {periodOptions.map((option) => (
                <MenuItem key={option.value} value={option.value}>
                  {option.label}
                </MenuItem>
              ))}
            </Select>
          </FormControl>
        </Box>
      </CardContent>
    </Card>
  );
};

export default PeriodFilter;
