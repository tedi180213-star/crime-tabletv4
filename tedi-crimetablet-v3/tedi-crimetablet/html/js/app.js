// ===== CRIME TABLET - MAIN APP =====

let playerData = {
    level: 0,
    xp: 0,
    cash: 0,
    crypto: 0,
    boostLevel: 0,
    boostsCompleted: 0,
    totalEarnings: 0,
    heistLevel: 0,
    transactions: []
};

let currentApp = 'home';
let activeContract = null;
let selectedHeist = null;
let selectedMarketCategory = 'weapons';
let hackCallback = null;

// ===== NUI MESSAGE HANDLER =====
window.addEventListener('message', function(event) {
    const data = event.data;

    switch(data.action) {
        case 'open':
            openTablet(data.playerData);
            break;
        case 'close':
            closeTablet();
            break;
        case 'updatePlayerData':
            updatePlayerData(data.playerData);
            break;
        case 'contractAccepted':
            onContractAccepted(data.contract);
            break;
        case 'contractUpdate':
            updateContractProgress(data.stage, data.progress);
            break;
        case 'hackResult':
            onHackResult(data.success);
            break;
        case 'heistUpdate':
            updateHeistProgress(data);
            break;
        case 'notification':
            showNotification(data.message, data.type);
            break;
        case 'marketUpdate':
            updateMarketStock(data.items);
            break;
    }
});

// ===== TABLET OPEN/CLOSE =====
function openTablet(data) {
    if (data) {
        playerData = { ...playerData, ...data };
    }
    document.getElementById('tablet-container').classList.remove('hidden');
    updateUI();
    updateTime();
}

function closeTablet() {
    document.getElementById('tablet-container').classList.add('hidden');
    goHome();
}

// ===== NAVIGATION =====
function openApp(appName) {
    document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
    document.getElementById(appName + '-screen').classList.add('active');
    currentApp = appName;

    switch(appName) {
        case 'boosting':
            initBoostingApp();
            break;
        case 'heist':
            initHeistApp();
            break;
        case 'blackmarket':
            initBlackMarketApp();
            break;
        case 'wallet':
            initWalletApp();
            break;
        case 'darkchat':
            initDarkChatApp();
            break;
    }
}

function goHome() {
    document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
    document.getElementById('home-screen').classList.add('active');
    currentApp = 'home';
}

// ===== UI UPDATE =====
function updateUI() {
    document.getElementById('boost-level').textContent = 'Level ' + playerData.boostLevel;
    document.getElementById('player-rep').textContent = playerData.level;
    document.getElementById('jobs-done').textContent = playerData.boostsCompleted;
    document.getElementById('wallet-balance').textContent = '$' + formatNumber(playerData.cash);
}

function updateTime() {
    const now = new Date();
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    document.getElementById('current-time').textContent = hours + ':' + minutes;
    setTimeout(updateTime, 30000);
}

function formatNumber(num) {
    if (num >= 1000000) return (num / 1000000).toFixed(1) + 'M';
    if (num >= 1000) return (num / 1000).toFixed(1) + 'K';
    return num.toString();
}

// ===== BOOSTING APP =====
function initBoostingApp() {
    const tabsContainer = document.getElementById('class-tabs');
    const classes = ['D', 'C', 'B', 'A', 'S'];
    const requiredLevels = [0, 5, 15, 30, 50];

    tabsContainer.innerHTML = classes.map((cls, i) => {
        const locked = playerData.boostLevel < requiredLevels[i];
        return `<div class="class-tab ${i === 0 ? 'active' : ''} ${locked ? 'locked' : ''}" 
                     onclick="${locked ? '' : `selectBoostClass('${cls}')`}"
                     data-class="${cls}">
                    ${cls} Class
                </div>`;
    }).join('');

    document.getElementById('boost-level-display').textContent = 'LVL ' + playerData.boostLevel;
    document.getElementById('xp-value').textContent = playerData.xp + '/100';
    document.getElementById('xp-fill').style.width = playerData.xp + '%';
    document.getElementById('boosts-completed').textContent = playerData.boostsCompleted;
    document.getElementById('total-earnings').textContent = '$' + formatNumber(playerData.totalEarnings);

    selectBoostClass('D');
}

function selectBoostClass(cls) {
    document.querySelectorAll('.class-tab').forEach(t => t.classList.remove('active'));
    document.querySelector(`.class-tab[data-class="${cls}"]`).classList.add('active');
    generateContracts(cls);
}

function generateContracts(cls) {
    const container = document.getElementById('contracts-container');
    const vehicles = {
        'D': [
            { name: 'Asea', icon: 'fa-car' },
            { name: 'Emperor', icon: 'fa-car-side' },
            { name: 'Stanier', icon: 'fa-car' },
            { name: 'Ingot', icon: 'fa-car-side' },
        ],
        'C': [
            { name: 'Fusilade', icon: 'fa-car-side' },
            { name: 'Penumbra', icon: 'fa-car' },
            { name: 'Prairie', icon: 'fa-car-side' },
            { name: 'Blista', icon: 'fa-car' },
        ],
        'B': [
            { name: 'Sultan', icon: 'fa-car' },
            { name: 'Kuruma', icon: 'fa-car-side' },
            { name: 'Schafter V12', icon: 'fa-car' },
            { name: 'Sentinel', icon: 'fa-car-side' },
        ],
        'A': [
            { name: 'Elegy RH8', icon: 'fa-car-side' },
            { name: 'Jester', icon: 'fa-car' },
            { name: 'Massacro', icon: 'fa-car-side' },
            { name: 'Comet', icon: 'fa-car' },
        ],
        'S': [
            { name: 'Zentorno', icon: 'fa-car' },
            { name: 'Turismo R', icon: 'fa-car-side' },
            { name: 'Entity XF', icon: 'fa-car' },
            { name: 'Krieger', icon: 'fa-car-side' },
        ]
    };

    const payouts = {
        'D': { min: 2000, max: 5000, crypto: '1-3' },
        'C': { min: 5000, max: 10000, crypto: '3-6' },
        'B': { min: 12000, max: 20000, crypto: '6-12' },
        'A': { min: 25000, max: 45000, crypto: '12-25' },
        'S': { min: 60000, max: 100000, crypto: '25-50' },
    };

    const payout = payouts[cls];
    const vehicleList = vehicles[cls] || vehicles['D'];

    container.innerHTML = vehicleList.map((v, i) => {
        const reward = Math.floor(Math.random() * (payout.max - payout.min) + payout.min);
        return `<div class="contract-item" onclick="acceptContract('${cls}', '${v.name}', ${reward})">
                    <div class="contract-item-icon">
                        <i class="fas ${v.icon}"></i>
                    </div>
                    <div class="contract-item-info">
                        <h4>${v.name}</h4>
                        <p>${cls} Class • Boost & Deliver</p>
                    </div>
                    <div class="contract-item-reward">
                        <div class="cash">$${formatNumber(reward)}</div>
                        <div class="crypto">+${payout.crypto} BTC</div>
                    </div>
                </div>`;
    }).join('');
}

function acceptContract(cls, vehicle, reward) {
    // Send to NUI
    fetch('https://tedi-crimetablet/acceptBoostContract', {
        method: 'POST',
        body: JSON.stringify({
            class: cls,
            vehicle: vehicle,
            reward: reward
        })
    }).then(resp => resp.json()).then(data => {
        if (data.success) {
            showActiveContract(cls, vehicle, reward);
            showNotification('Contract accepted! Go steal the vehicle.', 'success');
        } else {
            showNotification(data.message || 'Cannot accept contract right now.', 'error');
        }
    }).catch(() => {
        // Demo mode - show contract anyway
        showActiveContract(cls, vehicle, reward);
        showNotification('Contract accepted! Go steal the vehicle.', 'success');
    });
}

function showActiveContract(cls, vehicle, reward) {
    activeContract = { class: cls, vehicle: vehicle, reward: reward };
    document.getElementById('active-contract').classList.remove('hidden');
    document.getElementById('contract-vehicle-name').textContent = vehicle;
    document.getElementById('contract-class-label').textContent = cls + ' Class';
    document.getElementById('contract-reward-amount').textContent = '$' + formatNumber(reward);
    document.getElementById('contract-progress-fill').style.width = '10%';
    document.getElementById('step-steal').classList.add('active');
}

function updateContractProgress(stage, progress) {
    document.getElementById('contract-progress-fill').style.width = progress + '%';
    
    const steps = ['steal', 'hack', 'deliver'];
    steps.forEach(s => {
        document.getElementById('step-' + s).classList.remove('active', 'completed');
    });
    
    for (let i = 0; i < steps.indexOf(stage); i++) {
        document.getElementById('step-' + steps[i]).classList.add('completed');
    }
    document.getElementById('step-' + stage).classList.add('active');
}

// ===== HACK MINIGAME =====
function startHack(length, timer, callback) {
    hackCallback = callback;
    const overlay = document.getElementById('hack-overlay');
    overlay.classList.remove('hidden');
    
    const chars = '0123456789ABCDEF';
    let sequence = '';
    for (let i = 0; i < length; i++) {
        sequence += chars[Math.floor(Math.random() * chars.length)];
    }
    
    const sequenceContainer = document.getElementById('hack-sequence');
    sequenceContainer.innerHTML = sequence.split('').map(c => 
        `<div class="hack-char">${c}</div>`
    ).join('');
    
    const inputContainer = document.getElementById('hack-input');
    inputContainer.innerHTML = Array(length).fill('').map((_, i) => 
        `<div class="hack-char input-char" data-index="${i}">_</div>`
    ).join('');
    
    let currentIndex = 0;
    let timerValue = timer;
    document.getElementById('hack-timer').textContent = timerValue + 's';
    
    const timerInterval = setInterval(() => {
        timerValue--;
        document.getElementById('hack-timer').textContent = timerValue + 's';
        if (timerValue <= 0) {
            clearInterval(timerInterval);
            endHack(false);
        }
    }, 1000);
    
    // Show sequence briefly then hide
    setTimeout(() => {
        sequenceContainer.innerHTML = sequence.split('').map(c => 
            `<div class="hack-char">?</div>`
        ).join('');
    }, 3000);
    
    // Key listener for hack
    const hackListener = function(e) {
        if (currentIndex >= length) return;
        
        const key = e.key.toUpperCase();
        if (chars.includes(key)) {
            const inputChars = inputContainer.querySelectorAll('.input-char');
            inputChars[currentIndex].textContent = key;
            
            if (key === sequence[currentIndex]) {
                inputChars[currentIndex].classList.add('correct');
            } else {
                inputChars[currentIndex].classList.add('wrong');
                clearInterval(timerInterval);
                document.removeEventListener('keydown', hackListener);
                setTimeout(() => endHack(false), 500);
                return;
            }
            
            currentIndex++;
            if (currentIndex >= length) {
                clearInterval(timerInterval);
                document.removeEventListener('keydown', hackListener);
                setTimeout(() => endHack(true), 300);
            }
        }
    };
    
    document.addEventListener('keydown', hackListener);
}

function endHack(success) {
    document.getElementById('hack-overlay').classList.add('hidden');
    if (hackCallback) {
        hackCallback(success);
        hackCallback = null;
    }
    
    fetch('https://tedi-crimetablet/hackResult', {
        method: 'POST',
        body: JSON.stringify({ success: success })
    });
}

// ===== HEIST APP =====
function initHeistApp() {
    const container = document.getElementById('heist-list');
    const heists = [
        {
            id: 'fleeca',
            name: 'Fleeca Bank',
            desc: 'Small bank robbery. Quick in and out.',
            difficulty: 'Easy',
            payout: '$50K - $80K',
            crew: '2-3',
            requiredLevel: 0,
            stages: ['Setup', 'Hack Vault', 'Grab Cash', 'Escape'],
            icon: 'fa-building-columns'
        },
        {
            id: 'paleto',
            name: 'Paleto Bay Bank',
            desc: 'Medium difficulty heist in Paleto Bay.',
            difficulty: 'Medium',
            payout: '$120K - $180K',
            crew: '3-4',
            requiredLevel: 10,
            stages: ['Setup', 'Breach', 'Thermite Vault', 'Grab Cash', 'Escape'],
            icon: 'fa-landmark'
        },
        {
            id: 'pacific',
            name: 'Pacific Standard',
            desc: 'High-risk heist. Heavy police response.',
            difficulty: 'Hard',
            payout: '$300K - $500K',
            crew: '4',
            requiredLevel: 25,
            stages: ['Recon', 'Setup', 'Hack Security', 'Breach Vault', 'Escape'],
            icon: 'fa-building'
        },
        {
            id: 'union',
            name: 'Union Depository',
            desc: 'Legendary heist. Maximum security.',
            difficulty: 'Extreme',
            payout: '$750K - $1.2M',
            crew: '4',
            requiredLevel: 50,
            stages: ['Intel', 'Equipment', 'Infiltrate', 'Crack Vault', 'Extract', 'Escape'],
            icon: 'fa-vault'
        }
    ];

    container.innerHTML = heists.map(h => {
        const locked = playerData.heistLevel < h.requiredLevel;
        const diffClass = h.difficulty.toLowerCase();
        return `<div class="heist-card ${locked ? 'locked' : ''}" onclick="${locked ? '' : `selectHeist('${h.id}')`}">
                    <div class="heist-card-header">
                        <div class="heist-card-icon">
                            <i class="fas ${h.icon}"></i>
                        </div>
                        <div class="heist-card-title">
                            <h4>${h.name} ${locked ? '🔒' : ''}</h4>
                            <p>${h.desc}</p>
                        </div>
                    </div>
                    <div class="heist-card-footer">
                        <div class="heist-tags">
                            <span class="tag difficulty ${diffClass}">${h.difficulty}</span>
                            <span class="tag payout">${h.payout}</span>
                            <span class="tag crew"><i class="fas fa-users"></i> ${h.crew}</span>
                        </div>
                    </div>
                </div>`;
    }).join('');

    document.getElementById('heist-detail').classList.add('hidden');
    document.getElementById('heist-list').classList.remove('hidden');
    document.getElementById('heist-level-display').textContent = 'LVL ' + playerData.heistLevel;
}

function selectHeist(heistId) {
    const heists = {
        'fleeca': { name: 'Fleeca Bank', desc: 'Small bank robbery. Quick in and out.', difficulty: 'Easy', payout: '$50K - $80K', crew: 3, stages: ['Setup', 'Hack Vault', 'Grab Cash', 'Escape'] },
        'paleto': { name: 'Paleto Bay Bank', desc: 'Medium difficulty heist in Paleto Bay.', difficulty: 'Medium', payout: '$120K - $180K', crew: 4, stages: ['Setup', 'Breach', 'Thermite Vault', 'Grab Cash', 'Escape'] },
        'pacific': { name: 'Pacific Standard', desc: 'High-risk heist. Heavy police response.', difficulty: 'Hard', payout: '$300K - $500K', crew: 4, stages: ['Recon', 'Setup', 'Hack Security', 'Breach Vault', 'Escape'] },
        'union': { name: 'Union Depository', desc: 'Legendary heist. Maximum security.', difficulty: 'Extreme', payout: '$750K - $1.2M', crew: 4, stages: ['Intel', 'Equipment', 'Infiltrate', 'Crack Vault', 'Extract', 'Escape'] }
    };

    selectedHeist = heists[heistId];
    selectedHeist.id = heistId;

    document.getElementById('heist-list').classList.add('hidden');
    document.getElementById('heist-detail').classList.remove('hidden');

    document.getElementById('heist-detail-name').textContent = selectedHeist.name;
    document.getElementById('heist-detail-desc').textContent = selectedHeist.desc;
    document.getElementById('heist-detail-difficulty').textContent = selectedHeist.difficulty;
    document.getElementById('heist-detail-difficulty').className = 'tag difficulty ' + selectedHeist.difficulty.toLowerCase();
    document.getElementById('heist-detail-payout').textContent = selectedHeist.payout;

    // Crew slots
    const crewSlots = document.getElementById('crew-slots');
    crewSlots.innerHTML = '';
    for (let i = 0; i < selectedHeist.crew; i++) {
        const filled = i === 0; // First slot is always the player
        crewSlots.innerHTML += `<div class="crew-slot ${filled ? 'filled' : ''}">
            <i class="fas ${filled ? 'fa-user' : 'fa-plus'}"></i>
        </div>`;
    }

    // Stages
    const stagesList = document.getElementById('heist-stages');
    stagesList.innerHTML = selectedHeist.stages.map((stage, i) => 
        `<div class="stage-item">
            <div class="stage-number">${i + 1}</div>
            <span class="stage-name">${stage}</span>
        </div>`
    ).join('');
}

function inviteCrew() {
    fetch('https://tedi-crimetablet/inviteCrew', {
        method: 'POST',
        body: JSON.stringify({ heistId: selectedHeist.id })
    }).then(resp => resp.json()).then(data => {
        if (data.success) {
            showNotification('Invite sent to nearby players!', 'info');
        }
    }).catch(() => {
        showNotification('Invite sent to nearby players!', 'info');
    });
}

function startHeist() {
    fetch('https://tedi-crimetablet/startHeist', {
        method: 'POST',
        body: JSON.stringify({ heistId: selectedHeist.id })
    }).then(resp => resp.json()).then(data => {
        if (data.success) {
            showNotification('Heist started! Follow the objectives.', 'success');
            closeTablet();
        } else {
            showNotification(data.message || 'Cannot start heist.', 'error');
        }
    }).catch(() => {
        showNotification('Heist started! Follow the objectives.', 'success');
    });
}

function updateHeistProgress(data) {
    if (!selectedHeist) return;
    const stageItems = document.querySelectorAll('.stage-item');
    stageItems.forEach((item, i) => {
        item.classList.remove('active', 'completed');
        if (i < data.currentStage) item.classList.add('completed');
        if (i === data.currentStage) item.classList.add('active');
    });
}

// ===== BLACK MARKET APP (Player Listings) =====
let marketListings = [];
let myListings = [];
let currentMarketTab = 'listings';

function initBlackMarketApp() {
    document.getElementById('player-balance').textContent = '$' + formatNumber(playerData.cash);
    loadMarketListings();
}

function switchMarketTab(tab) {
    currentMarketTab = tab;
    document.querySelectorAll('.market-tab').forEach(t => t.classList.remove('active'));
    document.querySelector(`.market-tab[data-tab="${tab}"]`).classList.add('active');
    
    if (tab === 'listings') {
        loadMarketListings();
    } else {
        loadMyListings();
    }
}

function loadMarketListings() {
    fetch('https://tedi-crimetablet/getMarketListings', {
        method: 'POST',
        body: JSON.stringify({})
    }).then(resp => resp.json()).then(data => {
        marketListings = data.listings || [];
        renderListings(marketListings);
    }).catch(() => {
        // Demo data
        marketListings = [
            { id: 1, seller: 'Anonymous#4821', item: 'Lockpick', price: 450, qty: 5, desc: 'Quality picks' },
            { id: 2, seller: 'Anonymous#1337', item: 'Thermite', price: 4500, qty: 2, desc: 'Hot deal' },
            { id: 3, seller: 'Anonymous#7290', item: 'Encrypted Radio', price: 2800, qty: 3, desc: 'Clean frequency' },
            { id: 4, seller: 'Anonymous#5512', item: 'VPN Device', price: 3500, qty: 1, desc: 'Untraceable' },
            { id: 5, seller: 'Anonymous#9001', item: 'Hacking Laptop', price: 7000, qty: 1, desc: 'Pre-loaded tools' },
            { id: 6, seller: 'Anonymous#2244', item: 'Advanced Lockpick', price: 1800, qty: 4, desc: 'Fast entry' },
        ];
        renderListings(marketListings);
    });
}

function loadMyListings() {
    fetch('https://tedi-crimetablet/getMyListings', {
        method: 'POST',
        body: JSON.stringify({})
    }).then(resp => resp.json()).then(data => {
        myListings = data.listings || [];
        renderListings(myListings, true);
    }).catch(() => {
        myListings = [];
        renderListings(myListings, true);
    });
}

function renderListings(listings, isMine) {
    const container = document.getElementById('market-listings');
    if (listings.length === 0) {
        container.innerHTML = `<div class="empty-state">
            <i class="fas fa-box-open" style="font-size:32px;color:var(--text-muted)"></i>
            <p style="color:var(--text-muted);margin-top:8px">${isMine ? 'You have no active listings' : 'No listings available'}</p>
        </div>`;
        return;
    }
    
    container.innerHTML = listings.map(l => `
        <div class="listing-card" onclick="${isMine ? `removeListing(${l.id})` : `buyListing(${l.id}, '${l.item}', ${l.price})`}">
            <div class="listing-seller"><i class="fas fa-user-secret"></i> ${l.seller || 'You'}</div>
            <div class="listing-name">${l.item}</div>
            <div class="listing-desc">${l.desc || ''}</div>
            <div class="listing-footer">
                <span class="listing-price">$${formatNumber(l.price)}</span>
                <span class="listing-qty">x${l.qty}</span>
            </div>
        </div>
    `).join('');
}

function buyListing(id, item, price) {
    fetch('https://tedi-crimetablet/buyListing', {
        method: 'POST',
        body: JSON.stringify({ listingId: id, item: item, price: price })
    }).then(resp => resp.json()).then(data => {
        if (data.success) {
            showNotification(`Purchased ${item}!`, 'success');
            playerData.cash -= price;
            document.getElementById('player-balance').textContent = '$' + formatNumber(playerData.cash);
            loadMarketListings();
        } else {
            showNotification(data.message || 'Purchase failed.', 'error');
        }
    }).catch(() => {
        showNotification(`Purchased ${item}!`, 'success');
        playerData.cash -= price;
        document.getElementById('player-balance').textContent = '$' + formatNumber(playerData.cash);
        marketListings = marketListings.filter(l => l.id !== id);
        renderListings(marketListings);
    });
}

function removeListing(id) {
    fetch('https://tedi-crimetablet/removeListing', {
        method: 'POST',
        body: JSON.stringify({ listingId: id })
    }).then(resp => resp.json()).then(data => {
        if (data.success) {
            showNotification('Listing removed!', 'info');
            loadMyListings();
        }
    }).catch(() => {
        showNotification('Listing removed!', 'info');
        myListings = myListings.filter(l => l.id !== id);
        renderListings(myListings, true);
    });
}

function openListItemModal() {
    document.getElementById('list-item-modal').classList.remove('hidden');
}

function closeListItemModal() {
    document.getElementById('list-item-modal').classList.add('hidden');
}

function confirmListItem() {
    const name = document.getElementById('list-item-name').value;
    const price = parseInt(document.getElementById('list-item-price').value);
    const qty = parseInt(document.getElementById('list-item-qty').value) || 1;
    const desc = document.getElementById('list-item-desc').value;
    
    if (!name || !price) {
        showNotification('Enter item name and price!', 'error');
        return;
    }
    
    fetch('https://tedi-crimetablet/listItem', {
        method: 'POST',
        body: JSON.stringify({ item: name, price: price, qty: qty, desc: desc })
    }).then(resp => resp.json()).then(data => {
        if (data.success) {
            showNotification(`Listed ${name} for $${formatNumber(price)}!`, 'success');
            closeListItemModal();
            document.getElementById('list-item-name').value = '';
            document.getElementById('list-item-price').value = '';
            document.getElementById('list-item-qty').value = '1';
            document.getElementById('list-item-desc').value = '';
        } else {
            showNotification(data.message || 'Failed to list item.', 'error');
        }
    }).catch(() => {
        showNotification(`Listed ${name} for $${formatNumber(price)}!`, 'success');
        closeListItemModal();
    });
}

// ===== DARK CHAT APP =====
let currentChannel = 'global';
let chatMessages = {};

function initDarkChatApp() {
    if (!chatMessages['global']) {
        chatMessages['global'] = [
            { sender: 'Anon#4821', msg: 'Anyone need a driver tonight?', time: '2m ago', self: false },
            { sender: 'Anon#1337', msg: 'Got a clean Kuruma if anyone needs', time: '5m ago', self: false },
            { sender: 'Anon#9001', msg: 'Cops are patrolling heavy near Paleto', time: '8m ago', self: false },
        ];
        chatMessages['deals'] = [
            { sender: 'Anon#7290', msg: 'WTS: Lockpicks x10 - $400 each', time: '1m ago', self: false },
            { sender: 'Anon#5512', msg: 'Looking for thermite, paying extra', time: '4m ago', self: false },
        ];
        chatMessages['crew'] = [
            { sender: 'Anon#2244', msg: 'Need 2 for Fleeca, experienced only', time: '3m ago', self: false },
        ];
        chatMessages['intel'] = [
            { sender: 'Anon#6699', msg: 'Scanner: 3 units heading to Sandy', time: '1m ago', self: false },
            { sender: 'Anon#3377', msg: 'Heli spotted over LS docks', time: '6m ago', self: false },
        ];
    }
    switchChannel('global');
}

function switchChannel(channel) {
    currentChannel = channel;
    document.querySelectorAll('.chat-channel').forEach(c => c.classList.remove('active'));
    document.querySelector(`.chat-channel[data-channel="${channel}"]`).classList.add('active');
    renderChatMessages();
}

function renderChatMessages() {
    const container = document.getElementById('chat-messages');
    const msgs = chatMessages[currentChannel] || [];
    
    container.innerHTML = msgs.map(m => `
        <div class="chat-msg ${m.self ? 'self' : 'other'}">
            <div class="msg-header">${m.sender}</div>
            <div class="msg-bubble">${m.msg}</div>
            <div class="msg-time">${m.time}</div>
        </div>
    `).join('');
    
    container.scrollTop = container.scrollHeight;
}

function sendChatMessage() {
    const input = document.getElementById('chat-input');
    const msg = input.value.trim();
    if (!msg) return;
    
    // Send to server
    fetch('https://tedi-crimetablet/sendChatMessage', {
        method: 'POST',
        body: JSON.stringify({ channel: currentChannel, message: msg })
    }).catch(() => {});
    
    // Add locally
    if (!chatMessages[currentChannel]) chatMessages[currentChannel] = [];
    chatMessages[currentChannel].push({
        sender: 'You',
        msg: msg,
        time: 'now',
        self: true
    });
    
    renderChatMessages();
    input.value = '';
}

// ===== WALLET APP =====
function initWalletApp() {
    document.getElementById('wallet-total').textContent = '$' + formatNumber(playerData.cash + (playerData.crypto * 1000));
    document.getElementById('wallet-cash').textContent = '$' + formatNumber(playerData.cash);
    document.getElementById('wallet-crypto').textContent = playerData.crypto + ' BTC';

    const transactionsList = document.getElementById('transactions-list');
    if (playerData.transactions && playerData.transactions.length > 0) {
        transactionsList.innerHTML = playerData.transactions.map(t => {
            const isIncome = t.amount > 0;
            return `<div class="transaction-item">
                        <div class="transaction-icon ${isIncome ? 'income' : 'expense'}">
                            <i class="fas ${isIncome ? 'fa-arrow-down' : 'fa-arrow-up'}"></i>
                        </div>
                        <div class="transaction-info">
                            <h5>${t.label}</h5>
                            <span>${t.time || 'Just now'}</span>
                        </div>
                        <span class="transaction-amount ${isIncome ? 'positive' : 'negative'}">
                            ${isIncome ? '+' : ''}$${formatNumber(Math.abs(t.amount))}
                        </span>
                    </div>`;
        }).join('');
    } else {
        transactionsList.innerHTML = `<div class="transaction-item">
            <div class="transaction-icon info">
                <i class="fas fa-info"></i>
            </div>
            <div class="transaction-info">
                <h5>No transactions yet</h5>
                <span>Complete jobs to earn money</span>
            </div>
        </div>`;
    }
}

// ===== NOTIFICATIONS =====
function showNotification(message, type = 'info') {
    const container = document.getElementById('notification-container');
    const notif = document.createElement('div');
    notif.className = `notification ${type}`;
    
    const icons = {
        'success': 'fa-check-circle',
        'error': 'fa-exclamation-circle',
        'info': 'fa-info-circle'
    };
    
    notif.innerHTML = `<i class="fas ${icons[type] || icons.info}"></i><span>${message}</span>`;
    container.appendChild(notif);
    
    setTimeout(() => {
        notif.style.opacity = '0';
        notif.style.transform = 'translateX(100%)';
        setTimeout(() => notif.remove(), 300);
    }, 4000);
}

// ===== PLAYER DATA UPDATE =====
function updatePlayerData(data) {
    playerData = { ...playerData, ...data };
    updateUI();
}

// ===== KEYBOARD HANDLER =====
document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        if (!document.getElementById('hack-overlay').classList.contains('hidden')) {
            return; // Don't close during hack
        }
        closeTablet();
        fetch('https://tedi-crimetablet/closeTablet', { method: 'POST', body: JSON.stringify({}) });
    }
});

// ===== INITIAL STATE (for demo/testing) =====
// Uncomment below for standalone browser testing
// openTablet({ level: 5, xp: 45, cash: 25000, crypto: 12, boostLevel: 8, boostsCompleted: 23, totalEarnings: 185000, heistLevel: 5, transactions: [{label: 'Boost Payout', amount: 7500, time: '2 min ago'}, {label: 'Black Market', amount: -5000, time: '10 min ago'}] });
