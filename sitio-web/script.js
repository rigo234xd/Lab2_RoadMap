document.addEventListener('DOMContentLoaded', () => {
    // 1. Lógica para el menú hamburguesa en dispositivos móviles
    const btn = document.getElementById('mobile-menu-btn');
    const menu = document.getElementById('mobile-menu');

    if (btn && menu) {
        btn.addEventListener('click', () => {
            menu.classList.toggle('hidden');
        });

        // Cerrar menú al hacer clic en un enlace (para móviles)
        const mobileLinks = menu.querySelectorAll('a');
        mobileLinks.forEach(link => {
            link.addEventListener('click', () => {
                menu.classList.add('hidden');
            });
        });
    }

    // 2. Lógica del Formulario Inteligente de Emergencia (Variables Temporales)
    const smartForm = document.getElementById('smartForm');
    const smartResults = document.getElementById('smartResults');
    const smartInfo = document.getElementById('smartInfo');
    const googleMapsLink = document.getElementById('googleMapsLink');

    if (smartForm) {
        smartForm.addEventListener('submit', (e) => {
            e.preventDefault();

            // Obtener variables temporales del DOM
            const problemType = document.getElementById('problemType').value;
            const userLocation = document.getElementById('userLocation').value.trim();

            // Mostrar estado de carga en el botón
            const btnSubmit = smartForm.querySelector('button[type="submit"]');
            const originalBtnText = btnSubmit.innerHTML;
            btnSubmit.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Buscando...';
            btnSubmit.disabled = true;

            // Procesamiento simulado
            setTimeout(() => {
                btnSubmit.innerHTML = originalBtnText;
                btnSubmit.disabled = false;

                let infoText = "";
                let searchQuery = "";

                // Lógica de decisiones basada en las variables temporales
                switch (problemType) {
                    case 'grua':
                        infoText = "<strong>Recomendación:</strong> Estaciona en la berma, enciende luces de emergencia y ubícate detrás de las barreras de contención si estás en autopista.";
                        searchQuery = "Grúas de remolque cerca de " + userLocation;
                        break;
                    case 'bateria':
                        infoText = "<strong>Tip Rápido:</strong> Si tienes cables pasa corriente, busca otro conductor. Conecta positivo (rojo) con positivo, y negativo (negro) a una pieza metálica sin pintura.";
                        searchQuery = "Asistencia batería automóvil en " + userLocation;
                        break;
                    case 'neumatico':
                        infoText = "<strong>Seguridad:</strong> Ponte el chaleco reflectante antes de salir del vehículo. Coloca el triángulo a unos 50 metros de distancia hacia atrás.";
                        searchQuery = "Vulcanización más cercana a " + userLocation;
                        break;
                    case 'choque':
                        infoText = "<strong>¡ALERTA!</strong> Prioriza la salud. Si hay heridos llama al 131 (Ambulancia) o 133 (Carabineros). Si fue leve, toma fotografías antes de mover los autos.";
                        searchQuery = "Comisaría o urgencias en " + userLocation;
                        break;
                    default:
                        infoText = "<strong>Aviso:</strong> Si notas calentamiento o luz roja en el tablero de 'Check Engine', detén el motor inmediatamente para no agravar la falla.";
                        searchQuery = "Taller mecánico en " + userLocation;
                }

                // Construcción de URL usando la API universal de Google Maps
                const encodedSearch = encodeURIComponent(searchQuery);
                const mapsUrl = `https://www.google.com/maps/search/?api=1&query=${encodedSearch}`;

                // Inyectar datos en la interfaz
                smartInfo.innerHTML = infoText;
                googleMapsLink.href = mapsUrl;

                // Mostrar resultados
                smartResults.classList.remove('hidden');
            }, 1000);
        });
    }

    // 3. Lógica del Buscador RoadMap y Gadgets
    const searchInput = document.getElementById('searchInput');
    const searchBtn = document.getElementById('searchBtn');
    const mapFrame = document.getElementById('mapFrame');
    const clockElement = document.getElementById('clock');
    const tempElement = document.getElementById('temp');

    if (searchInput && searchBtn && mapFrame) {
        // Reloj
        function updateClock() {
            const now = new Date();
            const hours = String(now.getHours()).padStart(2, '0');
            const minutes = String(now.getMinutes()).padStart(2, '0');
            if (clockElement) clockElement.textContent = `${hours}:${minutes}`;
        }
        updateClock();
        setInterval(updateClock, 60000);

        // Temperatura real usando Open-Meteo API 
        let currentTemp = 0;
        let userLat = -41.4731; // Por defecto puerto montt
        let userLng = -73.0676;

        function updateTemp() {
            const meteoUrl = `https://api.open-meteo.com/v1/forecast?latitude=${userLat}&longitude=${userLng}&current_weather=true`;

            fetch(meteoUrl)
                .then(response => {
                    if (!response.ok) throw new Error("Error en la respuesta de la API");
                    return response.json();
                })
                .then(data => {
                    currentTemp = Math.round(data.current_weather.temperature);
                    if (tempElement) tempElement.textContent = `${currentTemp}°C`;
                })
                .catch(error => {
                    console.error('Error al obtener clima:', error);
                    if (tempElement) tempElement.textContent = "--°C";
                });
        }

        // Actualizar cada 10 minutos (600000 ms) para no agotar el límite de la API gratuita
        setInterval(updateTemp, 600000);

        // Búsquedas Sugeridas (Basadas en palabras clave o ubicación)
        function generateTopResults(query) {
            const resultsContainer = document.getElementById('resultsList');
            if (!resultsContainer) return;

            // Animación de carga
            resultsContainer.innerHTML = '<div class="text-gray-400 text-sm text-center mt-10 flex flex-col items-center"><i class="fas fa-spinner fa-spin text-tuerca-red text-3xl mb-3"></i><span>Generando sugerencias específicas...</span></div>';

            setTimeout(() => {
                resultsContainer.innerHTML = ''; // Limpiar
                if (!query) return;

                const cleanQuery = query.trim().toLowerCase();
                let suggestions = [];

                // Lógica de palabras clave para sugerencias ultra-específicas
                if (cleanQuery.includes('vulca') || cleanQuery.includes('neumatico') || cleanQuery.includes('llanta') || cleanQuery.includes('rueda') || cleanQuery.includes('pinchazo')) {
                    suggestions = [
                        { title: `Vulcanizaciones`, desc: `Reparación de neumáticos pinchados cerca`, icon: `fa-circle-notch` },
                        { title: `Venta de Neumáticos`, desc: `Tiendas de llantas y ruedas nuevas`, icon: `fa-compact-disc` },
                        { title: `Asistencia en Ruta`, desc: `Grúas y cambio de rueda a domicilio`, icon: `fa-truck-pickup` }
                    ];
                } else if (cleanQuery.includes('grua') || cleanQuery.includes('remolque') || cleanQuery.includes('panne') || cleanQuery.includes('choque')) {
                    suggestions = [
                        { title: `Grúas de Remolque`, desc: `Servicios de rescate y traslado de vehículos`, icon: `fa-truck-pickup` },
                        { title: `Asistencia Mecánica en Ruta`, desc: `Mecánicos a domicilio para emergencias`, icon: `fa-car-burst` },
                        { title: `Desabolladura y Pintura`, desc: `Talleres para reparar la carrocería`, icon: `fa-tools` }
                    ];
                } else if (cleanQuery.includes('bateria') || cleanQuery.includes('corriente') || cleanQuery.includes('electri')) {
                    suggestions = [
                        { title: `Asistencia de Batería`, desc: `Puente de corriente y rescate eléctrico`, icon: `fa-bolt` },
                        { title: `Venta de Baterías`, desc: `Tiendas de repuestos eléctricos para auto`, icon: `fa-car-battery` },
                        { title: `Talleres Eléctricos`, desc: `Especialistas en electricidad automotriz`, icon: `fa-plug` }
                    ];
                } else if (cleanQuery.includes('freno') || cleanQuery.includes('pastilla')) {
                    suggestions = [
                        { title: `Especialistas en Frenos`, desc: `Cambio de pastillas y rectificado de discos`, icon: `fa-car-crash` },
                        { title: `Repuestos de Frenos`, desc: `Tiendas de repuestos para sistema de frenado`, icon: `fa-store` },
                        { title: `Talleres Mecánicos`, desc: `Mecánica general y mantención preventiva`, icon: `fa-tools` }
                    ];
                } else if (cleanQuery.includes('aceite') || cleanQuery.includes('lubri') || cleanQuery.includes('filtro')) {
                    suggestions = [
                        { title: `Lubricentros`, desc: `Cambio de aceite y filtros rápidos`, icon: `fa-oil-can` },
                        { title: `Repuestos Generales`, desc: `Insumos, aceites y líquidos para auto`, icon: `fa-store` },
                        { title: `Talleres Mecánicos`, desc: `Mecánica general y mantención`, icon: `fa-tools` }
                    ];
                } else {
                    // Por defecto (si ingresan solo una ciudad o no coincide)
                    suggestions = [
                        { title: `Talleres Mecánicos`, desc: `Explora talleres mecánicos en la zona`, icon: `fa-tools` },
                        { title: `Servicio de Grúas`, desc: `Grúas y remolques disponibles cerca`, icon: `fa-truck-pickup` },
                        { title: `Vulcanización`, desc: `Reparación rápida de neumáticos`, icon: `fa-circle-notch` }
                    ];
                }

                // Insertar 3 resultados
                suggestions.forEach(suggestion => {
                    const searchIntent = `${suggestion.title} cerca de ${query}`;
                    const mapsUrl = `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(searchIntent)}`;

                    const resultCard = `
                        <div class="bg-white/5 border border-white/10 rounded-xl p-4 hover:bg-white/10 transition cursor-pointer transform hover:-translate-y-1 shrink-0">
                            <div class="flex items-center gap-3 mb-2">
                                <i class="fas ${suggestion.icon} text-tuerca-red text-xl"></i>
                                <h4 class="text-white font-bold text-[15px] leading-tight w-full" title="${suggestion.title}">${suggestion.title}</h4>
                            </div>
                            <div class="text-xs text-gray-400 mb-4 line-clamp-2">
                                ${suggestion.desc}
                            </div>
                            <a href="${mapsUrl}" target="_blank" class="block w-full text-center bg-gray-800 hover:bg-tuerca-red text-white text-xs font-semibold py-2 rounded transition border border-gray-700 hover:border-tuerca-red flex items-center justify-center gap-2">
                                <i class="fas fa-map-marked-alt"></i> Ver en Maps
                            </a>
                        </div>
                    `;
                    resultsContainer.innerHTML += resultCard;
                });
            }, 800);
        }

        // Búsqueda
        function searchLocation() {
            const query = searchInput.value.trim();
            if (query === '') {
                // Animación de error simple y borde rojo
                searchInput.classList.add('border-red-500', 'ring-red-500');
                setTimeout(() => searchInput.classList.remove('border-red-500', 'ring-red-500'), 1000);
                return;
            }
            const formattedQuery = encodeURIComponent(query);
            mapFrame.src = `https://maps.google.com/maps?q=${formattedQuery}&t=m&z=14&ie=UTF8&iwloc=&output=embed`;
            generateTopResults(query);
        }

        searchBtn.addEventListener('click', searchLocation);
        searchInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') searchLocation();
        });

        // Geolocalización y Carga Inicial
        const locationBtn = document.getElementById('locationBtn');

        function applyLocation(lat, lng) {
            userLat = lat;
            userLng = lng;
            updateTemp();
            searchInput.value = `${lat}, ${lng}`;
            searchLocation();
            setTimeout(() => { searchInput.value = ""; }, 500);
        }

        function loadDefaultLocation() {
            updateTemp();
            searchInput.value = "Llanquihue, Chile";
            searchLocation();
            setTimeout(() => { searchInput.value = ""; }, 500);
        }

        if (locationBtn) {
            locationBtn.addEventListener('click', () => {
                if (navigator.geolocation) {
                    searchInput.value = "Obteniendo ubicación...";
                    navigator.geolocation.getCurrentPosition(
                        (position) => {
                            applyLocation(position.coords.latitude, position.coords.longitude);
                        },
                        (error) => {
                            console.error("Error obteniendo ubicación:", error);
                            searchInput.value = "";
                            alert("No se pudo obtener tu ubicación automáticamente. Revisa los permisos de tu navegador o ingresa la ciudad manualmente.");
                        }
                    );
                } else {
                    alert("Tu navegador no soporta geolocalización.");
                }
            });
        }

        // Carga inicial automática usando ubicación del usuario
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(
                (position) => {
                    applyLocation(position.coords.latitude, position.coords.longitude);
                },
                (error) => {
                    console.error("Geolocalización inicial denegada o falló:", error);
                    loadDefaultLocation();
                }
            );
        } else {
            loadDefaultLocation();
        }
    }
});
