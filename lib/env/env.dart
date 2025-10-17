class Env {
  static const baseUrl = String.fromEnvironment('BASE_URL',
      defaultValue: 'https://uat.ado-dad.com');

  // Google Places API Key - Replace with your actual API key
  static const googlePlacesApiKey = String.fromEnvironment(
      'GOOGLE_PLACES_API_KEY',
      defaultValue: 'AIzaSyBn_S2uHfsabzh6jWvd9ckEyH88qnfdHQ0');
}
