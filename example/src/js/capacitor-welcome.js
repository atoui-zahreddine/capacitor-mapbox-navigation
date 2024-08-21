import { CapacitorMapboxNavigation } from '@atoui-zahreddine/capacitor-mapbox-navigation'
import { Geolocation } from '@capacitor/geolocation'

const navigateBtn = document.getElementById('navigate-btn')

navigateBtn.addEventListener('click', async () => {
  const long = +document.getElementById('longitude').value
  const lat = +document.getElementById('latitude').value
  await navigateToAddressWithMapbox({ latitude: lat, longitude: long })
})

export const navigateToAddressWithMapbox = async ({
  latitude = 0,
  longitude = 0,
}) => {
  if (!isAddressValid({ latitude, longitude })) {
    return
  }

  try {
    await startNavigation({ latitude, longitude })
  } catch (error) {
    handleDeniedLocation(error)
  }
}
const startNavigation = async ({ latitude, longitude }) => {
  const location = await Geolocation.getCurrentPosition({
    enableHighAccuracy: true,
  })

  const result = await CapacitorMapboxNavigation.show({
    routes: [
      {
        latitude: location.coords.latitude,
        longitude: location.coords.longitude,
      },
      { latitude: latitude, longitude: longitude },
    ],
  })

  if (result?.status === 'failure') {
    switch (result?.type) {
      case 'on_failure':
        toastError('No routes found', true)
        break
      case 'on_cancelled':
        toastError('Navigation cancelled', true)
        break
    }
  }
}

function isAddressValid({ latitude = 0, longitude = 0 }) {
  if (latitude === 0 || longitude === 0) {
    toastError('Activity Address is not available', true)
    return false
  }

  return true
}
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const handleDeniedLocation = (error) => {
  if (error?.type === 'not_supported') {
    return toastError('Navigation not supported on web', true)
  }
  toastError(
    'Error in getting location permission, please enable your gps location',
    true,
  )
}
