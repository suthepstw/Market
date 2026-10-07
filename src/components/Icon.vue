<script setup>
defineProps({ name: String, size: { default: 20 } })
const paths = {
 store:'M3 10h18M4 10v10h16V10M3 10l2-7h14l2 7M9 20v-6h6v6M3 10a3 3 0 006 0 3 3 0 006 0 3 3 0 006 0',
 box:'M21 8l-9-5-9 5 9 5 9-5zM3 8v10l9 5 9-5V8M12 13v10M7.5 5.5l9 5',
 dashboard:'M3 3h7v7H3zM14 3h7v7h-7zM3 14h7v7H3zM14 14h7v7h-7z',
 layers:'M12 3L2 8l10 5 10-5-10-5zM2 12l10 5 10-5M2 16l10 5 10-5',
 chevron:'M9 5l7 7-7 7', plus:'M12 5v14M5 12h14', search:'M21 21l-5-5M18 10a8 8 0 11-16 0 8 8 0 0116 0',
 grid:'M3 3h6v6H3zM15 3h6v6h-6zM3 15h6v6H3zM15 15h6v6h-6z', list:'M8 5h13M8 12h13M8 19h13M3 5h.01M3 12h.01M3 19h.01',
 filter:'M4 7h16M7 12h10M10 17h4', sort:'M7 3v18m-3-3l3 3 3-3M14 6h7M14 11h5M14 16h3',
 check:'M20 6l-11 11-5-5', alert:'M10.3 4L2 18a2 2 0 001.7 3h16.6a2 2 0 001.7-3L13.7 4a2 2 0 00-3.4 0zM12 9v4M12 17h.01',
 wallet:'M20 8V5a2 2 0 00-2-2H5a2 2 0 000 4h15v14H5a2 2 0 01-2-2V5M20 11h-5v6h5M16 14h.01',
 download:'M12 3v12M7 10l5 5 5-5M3 16v5h18v-5', upload:'M12 16V3M7 8l5-5 5 5M3 16v5h18v-5',
 edit:'M16 3l5 5-12 12-6 1 1-6L16 3zM13 6l5 5', clock:'M12 8v4l3 2M22 12a10 10 0 11-20 0 10 10 0 0120 0',
 close:'M6 6l12 12M18 6L6 18', arrow:'M5 12h14M14 7l5 5-5 5', logout:'M9 4H3v16h6M10 12h11M17 8l4 4-4 4',
 leaf:'M20 3C9 2 3 8 6 15c7 5 15-2 14-12zM4 21L16 8', heart:'M20.8 4.6a5.5 5.5 0 00-7.8 0L12 5.7l-1.1-1.1a5.5 5.5 0 00-7.8 7.8L12 21l8.8-8.6a5.5 5.5 0 000-7.8z'
}
</script>
<template><svg :width="size" :height="size" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.65" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path :d="paths[name] || paths.box" /></svg></template>
