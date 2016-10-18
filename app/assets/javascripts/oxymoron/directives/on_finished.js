angular.module("oxymoron.directives.onFinished", [])
  .directive('onFinished', ['$q', '$timeout', function($q, $timeout) {
    return {
      scope: {
        onFinished: "&"
      },
      require: 'form',
      link: function(scope, elm, attrs, ctrl) {
        scope.$on('loading:finish', function(event, result) {
          try {
            if (result.config.data.form_name == ctrl.$name) {
              $timeout(function() {
                try {
                  scope.onFinished()(result.data);
                }
                catch(e) {}
              });
            }   
          }
          catch(e) {}
        });
      }
    };
  }]);