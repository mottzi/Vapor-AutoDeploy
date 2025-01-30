class DeploymentSocket 
{
    constructor() 
    {
        this.socket = null;
        this.reconnectDelay = 5000;
        this.deploymentManager = new DeploymentManager();
    }

    connect()
    {
        this.socket = new WebSocket('wss://mottzi.de/admin/ws');
        console.log('WebSocket connected to server.')

        this.socket.onmessage = (event) => 
        {
            try 
            {
                const data = JSON.parse(event.data);
                this.handleMessage(data);
            } 
            catch (error) 
            {
                console.error('Failed to process message:', error);
            }
        };

        this.socket.onclose = () => 
        {
            console.log('WebSocket closed: Reconnecting...');
            setTimeout(() => this.connect(), this.reconnectDelay);
        };
    }

    handleMessage(data)
    {
        switch (data.type) 
        {
            case 'creation':
                console.log(`CREATION: ${data.deployment.id}`);
                this.deploymentManager.handleCreation(data.deployment);
                break;

            case 'update':
                console.log(`UPDATE: ${data.deployment.id}`);
                this.deploymentManager.handleUpdate(data.deployment);
                break;
        }
    }
}

class DeploymentManager 
{
    constructor() 
    {
        this.activeTimers = new Map();
    }

    handleCreation(deployment) 
    {
        const row = this.createRow(deployment);
        this.setupTimer(row, deployment);
    }

    handleUpdate(deployment) 
    {
        if (!deployment.finishedAt) return;

        const row = document.querySelector(`tr[data-deployment-id="${deployment.id}"]`);
        if (!row) return;

        this.clearTimer(deployment.id);
        this.updateCompletedRow(row, deployment);
    }

    createRow(deployment) 
    {
        const row = document.createElement('tr');
        row.className = 'hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors';
        row.dataset.deploymentId = deployment.id;
        row.dataset.startedAt = deployment.startedAtTimestamp;

        row.innerHTML = this.rowTemplate(deployment);
        
        const tbody = document.querySelector('tbody');
        tbody.prepend(row);
        return row;
    }

    rowTemplate(deployment) 
    {
        const datetime = this.formatDateTime(deployment.startedAt);
        const durationHtml = deployment.durationString
            ? `<span class="font-mono text-sm text-gray-600 dark:text-gray-300">${deployment.durationString}</span>`
            : this.loadingSpinnerHtml();

        return `
            <td class="px-6 py-4 whitespace-nowrap">
                <span class="block text-sm text-gray-600 dark:text-gray-300">${deployment.message}</span>
            </td>
            <td class="hidden sm:table-cell px-6 py-4 whitespace-nowrap">
                <a href="/admin/deployments/${deployment.id}" class="text-blue-600 hover:text-blue-900 dark:text-blue-400 dark:hover:text-blue-300 font-medium text-sm">${deployment.id}</a>
            </td>
            <td class="px-6 py-4 whitespace-nowrap">
                ${this.statusBadge(deployment.status)}
            </td>
            <td class="hidden sm:table-cell px-6 py-4 whitespace-nowrap">
                <span class="block text-sm text-gray-600 dark:text-gray-300">${datetime.date}</span>
                <span class="block text-gray-400 dark:text-gray-500 text-xs">${datetime.time}</span>
            </td>
            <td class="px-6 py-4 whitespace-nowrap">
                ${durationHtml}
            </td>
        `;
    }

    setupTimer(row, deployment) 
    {
        const durationElement = row.querySelector('.live-duration');
        const startTimestamp = parseFloat(row.dataset.startedAt);
        
        if (!durationElement || isNaN(startTimestamp)) return;

        const update = () => 
        {
            const now = Date.now() / 1000;
            durationElement.textContent = `${(now - startTimestamp).toFixed(1)}s`;
        };

        const intervalId = setInterval(update, 100);
        this.activeTimers.set(deployment.id, intervalId);
        update();
    }

    clearTimer(deploymentId) 
    {
        if (this.activeTimers.has(deploymentId)) 
        {
            clearInterval(this.activeTimers.get(deploymentId));
            this.activeTimers.delete(deploymentId);
        }
    }

    updateCompletedRow(row, deployment) 
    {
        const durationCell = row.querySelector('td:nth-child(5)');
        if (durationCell) { durationCell.innerHTML = `<span class="font-mono text-sm text-gray-600 dark:text-gray-300">${deployment.durationString}</span>`; }

        const statusCell = row.querySelector('td:nth-child(3)');
        if (statusCell) { statusCell.innerHTML = this.statusBadge(deployment.status); }
    }

    statusBadge(status) 
    {
        const classes = 
        {
            success: 'bg-green-100 text-green-800 dark:bg-green-800/30 dark:text-green-200',
            failure: 'bg-red-100 text-red-800 dark:bg-red-800/30 dark:text-red-200',
            running: 'bg-blue-100 text-blue-800 dark:bg-blue-800/30 dark:text-blue-200'
        };

        const labels = 
        {
            success: 'Success',
            failure: 'Failed',
            running: 'Running'
        };

        const badgeClass = classes[status] || classes.running;
        const label = labels[status] || status;

        return `<span class="status-badge px-3 py-1 rounded-full ${badgeClass} text-sm">${label}</span>`;
    }

    loadingSpinnerHtml() 
    {
        return `
            <div class="flex items-center text-gray-600 dark:text-gray-300">
                <svg class="animate-spin h-4 w-4 mr-2" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                    <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                <span class="live-duration font-mono text-sm">0.0s</span>
            </div>
        `;
    }

    formatDateTime(isoString) 
    {
        const date = new Date(isoString);
        return {
            date: date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }),
            time: date.toLocaleTimeString('en-US', { hour12: false })
        };
    }
}

document.addEventListener('DOMContentLoaded', () => 
{ 
    socket = new DeploymentSocket();
    socket.connect();
});