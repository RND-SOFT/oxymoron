angular.module("oxymoron.config.ngform", [])
  .config(['$provide', function($provide) {

    //embed current ngFormController to $form scope variable
    $provide.decorator('ngFormDirective', [
      '$delegate', '$timeout',function($delegate, $timeout) {

        var formDirective = $delegate[0];
        var oldCompile = formDirective.compile;

        formDirective.compile = function(tElement, tAttrs, transclude) {
          var compile = oldCompile ? oldCompile.apply(this, arguments) : {};
          var oldPost = compile.post;


          compile.post = function(scope, element, attrs, arg) {
            var ctrl = arg[0];
            scope.$form = ctrl;
            if (oldPost) {
              return oldPost.apply(this, arguments);
            }
          };
          return compile;
        };

        return $delegate;
      }
    ]);

  }])

