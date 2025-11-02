module.exports = {
  generateSearchTerm: function(requestParams, context, ee, next) {
    const searchTerms = [
      'web3', 'crypto', 'defi', 'nft', 'dao',
      'blockchain', 'ethereum', 'bitcoin', 'social',
      'builders', 'creators', 'developers'
    ];
    context.vars.randomSearchTerm = searchTerms[Math.floor(Math.random() * searchTerms.length)];
    return next();
  },

  generateAddress: function(requestParams, context, ee, next) {
    // Generate a mock Ethereum address
    context.vars.randomAddress = '0x' + Array(40).fill(0).map(() =>
      Math.floor(Math.random() * 16).toString(16)
    ).join('');
    return next();
  },

  generateCircleData: function(requestParams, context, ee, next) {
    const names = ['Tech Hub', 'Creative Space', 'Builders Guild', 'Innovation Lab', 'Community Circle'];
    const symbols = ['TCH', 'CRE', 'BLD', 'INN', 'COM'];
    const descriptions = [
      'A community for tech enthusiasts',
      'Creative minds collaborate here',
      'Building the future together',
      'Innovation starts here',
      'Community-driven development'
    ];

    const index = Math.floor(Math.random() * names.length);
    context.vars.randomCircleName = names[index];
    context.vars.randomSymbol = symbols[index] + Math.floor(Math.random() * 1000);
    context.vars.randomDescription = descriptions[index];
    context.vars.testPrivateKey = '0x' + '1'.repeat(64); // Test private key

    return next();
  }
};
