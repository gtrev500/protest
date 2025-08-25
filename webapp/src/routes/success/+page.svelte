<script>
  import { page } from '$app/stores';
  import { onMount } from 'svelte';

  let protestId = '';
  let publicUrl = '';

  onMount(() => {
    const url = new URL($page.url);
    protestId = url.searchParams.get('id') || '';
    if (protestId) {
      publicUrl = `${url.origin}/protest/${protestId}`;
    }
  });
</script>

<svelte:head>
  <title>Success | Protest Sourcebook</title>
</svelte:head>

<div class="min-h-screen bg-gray-100 py-12 px-4 sm:px-6 lg:px-8">
  <div class="max-w-md mx-auto bg-white rounded-lg shadow px-6 py-8">
    <div class="text-center">
      <div class="mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-green-100">
        <svg class="h-6 w-6 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
        </svg>
      </div>
      <h2 class="mt-4 text-2xl font-bold text-gray-900">Thank You!</h2>
      <p class="mt-1 text-gray-600">
        Your protest information has been successfully submitted.
      </p>
      
      {#if protestId}
        <div class="mt-6 bg-gray-50 rounded p-4">
          <p class="text-sm text-gray-700">Your submission ID:</p>
          <p class="font-mono text-lg text-gray-900">{protestId}</p>
          <p class="mt-1 text-sm text-gray-600">
            Public URL: <br />
            <code class="text-xs bg-gray-200 px-2 py-1 rounded">
              {publicUrl}
            </code>
          </p>
        </div>
      {/if}

      <div class="mt-8 space-y-3">
        <a
          href="/form"
          class="w-full inline-flex justify-center items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
        >
          Submit Another Protest
        </a>
        <a
          href="/log"
          class="w-full inline-flex justify-center items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
        >
          View Log
        </a>
        {#if protestId}
          <a
            href="/protest/{protestId}"
            class="w-full inline-flex justify-center items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
          >
            View Your Submission
          </a>
        {/if}
      </div>
    </div>
  </div>
</div>