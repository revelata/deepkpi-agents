# Chart Patterns Reference

Every chart in an Analysis Stress Test report uses Chart.js 4.x on a dark background
with the blue-family palette. This file shows the patterns for common chart types
you'll encounter when visualizing SEC filing data.

## Palette

```js
const B1 = '#4FEAFF';  // cyan — primary series
const B2 = '#90caf9';  // light blue — secondary
const B3 = '#5b8def';  // mid blue — tertiary
const B4 = '#a78bfa';  // periwinkle — quaternary
const grid = { color: 'rgba(255,255,255,0.05)' };
```

## Series differentiation (when you can't use color alone)

When multiple series appear on the same chart, differentiate with ALL THREE:
shade, dash pattern, and point shape.

| Series | Color | borderDash | pointStyle |
|--------|-------|-----------|------------|
| 1st    | B1    | `[]` (solid) | `'circle'` |
| 2nd    | B2    | `[6,3]` | `'rect'` |
| 3rd    | B3    | `[2,3]` | `'triangle'` |
| 4th    | B4    | `[8,4,2,4]` | `'rectRounded'` |

## Common chart types

### Single-series bar (positive/negative shading)

Good for: annual volume growth, single KPI trend with sign changes.

```js
new Chart(document.getElementById('cN'), {
  type: 'bar',
  data: {
    labels: ['FY20','FY21','FY22','FY23','FY24','FY25'],
    datasets: [{
      data: [10, 6, -5, -10, -5, 7],
      backgroundColor: [10,6,-5,-10,-5,7].map(v => v >= 0 ? B1+'99' : B1+'33'),
      borderColor: [10,6,-5,-10,-5,7].map(v => v >= 0 ? B1 : B1+'88'),
      borderWidth: 1, borderRadius: 4, barPercentage: 0.6
    }]
  },
  options: {
    responsive: true,
    plugins: {
      legend: { display: false },
      tooltip: { callbacks: { label: c => c.parsed.y + '%' }}
    },
    scales: {
      y: { ticks: { callback: v => v + '%' }, grid },
      x: { grid: { display: false }}
    }
  }
});
```

### Multi-series line (segments over time)

Good for: comparing segment volume, margin trends across divisions.

```js
new Chart(document.getElementById('cN'), {
  type: 'line',
  data: {
    labels: ['FQ1 24','FQ2 24','FQ3 24','FQ1 25','FQ2 25'],
    datasets: [
      {
        label: 'Segment A',
        data: [38, 22, -4, -16, 2],
        borderColor: B1, backgroundColor: B1+'18',
        tension: 0.35, pointRadius: 5, borderWidth: 2.5,
        borderDash: [], pointStyle: 'circle'
      },
      {
        label: 'Segment B',
        data: [43, 4, -3, -18, -3],
        borderColor: B2, backgroundColor: B2+'18',
        tension: 0.35, pointRadius: 5, borderWidth: 2.5,
        borderDash: [6,3], pointStyle: 'rect'
      }
    ]
  },
  options: {
    responsive: true,
    plugins: {
      legend: {
        position: 'bottom',
        labels: { usePointStyle: true, padding: 18 }
      }
    },
    scales: {
      y: { ticks: { callback: v => v + '%' }, grid },
      x: { grid: { display: false }}
    }
  }
});
```

### Dual-bar (revenue vs earnings for a segment)

Good for: showing revenue decline alongside earnings collapse.

```js
new Chart(document.getElementById('cN'), {
  type: 'bar',
  data: {
    labels: ['FQ2 24','FQ3 24','FQ1 25','FQ2 25','FQ3 25','FQ1 26','FQ2 26'],
    datasets: [
      {
        label: 'Revenue ($M)',
        data: [502, 526, 447, 446, 469, 362, 419],
        backgroundColor: B2+'55', borderColor: B2,
        borderWidth: 1, borderRadius: 4
      },
      {
        label: 'Adj EBIT ($M)',
        data: [92, 74, 60, 48, 61, 27, 22],
        backgroundColor: B1+'88', borderColor: B1,
        borderWidth: 1, borderRadius: 4
      }
    ]
  },
  options: {
    responsive: true,
    plugins: {
      legend: {
        position: 'bottom',
        labels: { usePointStyle: true, pointStyle: 'rect', padding: 16 }
      }
    },
    scales: {
      y: { ticks: { callback: v => '$' + v + 'M' }, grid },
      x: { grid: { display: false }}
    }
  }
});
```

### Mixed bar + line (volume bars with price/mix line overlay)

Good for: organic sales decomposition (volume vs price/mix).

```js
new Chart(document.getElementById('cN'), {
  type: 'bar',
  data: {
    labels: ['FQ1 24','FQ2 24','FQ3 24','FQ1 25','FQ2 25'],
    datasets: [
      {
        label: 'Organic Volume %',
        data: [-30, 4, -3, 43, -3],
        backgroundColor: [-30,4,-3,43,-3].map(v => v >= 0 ? B1+'77' : B2+'44'),
        borderColor: [-30,4,-3,43,-3].map(v => v >= 0 ? B1 : B2),
        borderWidth: 1, borderRadius: 3, barPercentage: 0.7
      },
      {
        label: 'Price/Mix %',
        data: [7, 5, -1, -5, -3],
        type: 'line', borderColor: B3, pointBackgroundColor: B3,
        pointRadius: 5, tension: 0.35, borderWidth: 2.5,
        borderDash: [6,3], pointStyle: 'rect'
      }
    ]
  },
  options: {
    responsive: true,
    plugins: {
      legend: {
        position: 'bottom',
        labels: { usePointStyle: true, padding: 16 }
      }
    },
    scales: {
      y: { ticks: { callback: v => v + '%' }, grid },
      x: { grid: { display: false }}
    }
  }
});
```

### Single-series line with fill (gross margin trend)

Good for: showing margin recovery or deterioration over time.

```js
new Chart(document.getElementById('cN'), {
  type: 'line',
  data: {
    labels: ['FQ1 23','FQ2 23','FQ3 23','FQ1 24','FQ2 24'],
    datasets: [{
      label: 'Gross Margin %',
      data: [36.0, null, 41.8, 38.4, 43.5],
      borderColor: B1, backgroundColor: B1+'10',
      fill: true, tension: 0.35,
      pointRadius: 5, pointBackgroundColor: B1,
      borderWidth: 2.5, spanGaps: true
    }]
  },
  options: {
    responsive: true,
    plugins: {
      legend: { display: false },
      tooltip: { callbacks: { label: c => c.parsed.y.toFixed(1) + '%' }}
    },
    scales: {
      y: { min: 34, max: 48, ticks: { callback: v => v + '%' }, grid },
      x: { grid: { display: false }}
    }
  }
});
```

## When to use each chart type

| Data pattern | Chart type |
|-------------|-----------|
| Single KPI with sign changes over time | Single-series bar with pos/neg shading |
| Comparing 2-4 segments over time | Multi-series line |
| Revenue alongside earnings for a segment | Dual-bar |
| Volume vs price/mix decomposition | Mixed bar + line |
| Single margin or ratio trend | Single-series line with fill |
| Quarterly earnings for deleveraging story | Single-series bar (all positive, uniform color) |

## Global defaults (set once at the top of the script block)

```js
Chart.defaults.color = '#8b949e';
Chart.defaults.borderColor = '#2a313a';
Chart.defaults.font.family = "'Inter', system-ui, sans-serif";
Chart.defaults.font.size = 11;
```

## Choosing which arguments get charts

Not every argument needs a chart. Use charts when:
- There are 4+ data points that form a visual trend
- The comparison between two series tells a story (e.g., revenue flat but earnings collapsing)
- Positive/negative sign changes are meaningful
- The visual pattern is more compelling than stating numbers in prose

Skip charts when:
- The argument hinges on 1-2 numbers (just state them in the evidence card)
- The data is qualitative (e.g., management commentary)
- Adding a chart would just restate what the evidence text already says
