import React from 'react';
import {
  Card,
  CardContent,
  CardHeader,
  Typography,
  Box,
  useTheme,
} from '@mui/material';
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';
import { DashboardMetrics } from '../types';

interface DailyRecordingsChartProps {
  metrics: DashboardMetrics;
  loading?: boolean;
}

const DailyRecordingsChart: React.FC<DailyRecordingsChartProps> = ({ metrics, loading = false }) => {
  const theme = useTheme();

  // Prepare chart data - sort by date and format
  const chartData = metrics.daily_recordings
    .map(record => ({
      ...record,
      formattedDate: new Date(record.date).toLocaleDateString('fr-FR', {
        month: 'short',
        day: 'numeric',
      }),
    }))
    .sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());

  const CustomTooltip = ({ active, payload, label }: { active?: boolean; payload?: Array<{ value: number }>; label?: string }) => {
    if (active && payload && payload.length) {
      return (
        <Box
          sx={{
            backgroundColor: 'background.paper',
            border: '1px solid',
            borderColor: 'divider',
            borderRadius: 1,
            p: 1.5,
            boxShadow: 2,
          }}
        >
          <Typography variant="body2" sx={{ fontWeight: 600 }}>
            {label}
          </Typography>
          <Typography variant="body2" color="primary">
            {`Enregistrements: ${payload[0].value}`}
          </Typography>
        </Box>
      );
    }
    return null;
  };

  if (loading) {
    return (
      <Card sx={{ mb: 4 }}>
        <CardHeader title="Activité quotidienne" />
        <CardContent>
          <Box sx={{ height: 300, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Typography color="text.secondary">Chargement des données...</Typography>
          </Box>
        </CardContent>
      </Card>
    );
  }

  if (chartData.length === 0) {
    return (
      <Card sx={{ mb: 4 }}>
        <CardHeader title="Activité quotidienne" />
        <CardContent>
          <Box sx={{ height: 300, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Typography color="text.secondary">Aucune donnée disponible</Typography>
          </Box>
        </CardContent>
      </Card>
    );
  }

  const totalRecordings = chartData.reduce((sum, item) => sum + item.count, 0);
  const averagePerDay = totalRecordings / chartData.length;
  const maxRecordings = Math.max(...chartData.map(item => item.count));

  return (
    <Card sx={{ mb: 4 }}>
      <CardHeader
        title="Activité quotidienne"
        subheader={`${totalRecordings} enregistrements sur les ${chartData.length} derniers jours`}
        action={
          <Box sx={{ textAlign: 'right' }}>
            <Typography variant="body2" color="text.secondary">
              Moyenne: {averagePerDay.toFixed(1)}/jour
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Maximum: {maxRecordings}
            </Typography>
          </Box>
        }
      />
      <CardContent>
        <Box sx={{ height: 300, width: '100%' }}>
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={chartData} margin={{ top: 5, right: 30, left: 20, bottom: 5 }}>
              <CartesianGrid strokeDasharray="3 3" stroke={theme.palette.divider} />
              <XAxis
                dataKey="formattedDate"
                axisLine={false}
                tickLine={false}
                tick={{ fontSize: 12, fill: theme.palette.text.secondary }}
              />
              <YAxis
                axisLine={false}
                tickLine={false}
                tick={{ fontSize: 12, fill: theme.palette.text.secondary }}
              />
              <Tooltip content={<CustomTooltip />} />
              <Area
                type="monotone"
                dataKey="count"
                stroke={theme.palette.primary.main}
                strokeWidth={2}
                fill={`${theme.palette.primary.main}30`}
                fillOpacity={0.6}
              />
            </AreaChart>
          </ResponsiveContainer>
        </Box>
      </CardContent>
    </Card>
  );
};

export default DailyRecordingsChart;
