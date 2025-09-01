<script>
  import ProtestDashboard from '$lib/components/ProtestDashboard.svelte';
  import { page } from '$app/state';
  
  let showMetrics = $derived(page.url.searchParams.get('metrics') === 'true');
</script>

<svelte:head>
  <title>Log | Protest Sourcebook</title>
</svelte:head>

<ProtestDashboard {showMetrics} />