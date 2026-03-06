using FluentValidation;
using MediatR;


namespace HealtHub.Application.Behaviors
{
    internal class ValidationBehaviors<TRequest, TRespones>(IEnumerable<IValidator<TRequest>> Validators)
        : IPipelineBehavior<TRequest, TRespones> where TRequest : notnull
    {
        public async Task<TRespones> Handle(TRequest request, RequestHandlerDelegate<TRespones> next, CancellationToken cancellationToken)
        {
            if (!Validators.Any())
                return await next();

            var context = new ValidationContext<TRequest>(request);

            var result = await Task.WhenAll(Validators.Select(v => v.ValidateAsync(context, cancellationToken)));

            var failures = result.SelectMany(r => r.Errors).Where(e => e is not null).ToList();

            if (failures.Any())
                throw new ValidationException(failures);

            return await next(cancellationToken);
        }
    }
}
