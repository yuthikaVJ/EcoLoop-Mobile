using EcoLoop.Api.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.EntityFrameworkCore;
using Npgsql;

namespace EcoLoop.Api.Controllers;

// Never retry mutations automatically: the caller must reload current state first.
public sealed class TransactionExceptionFilter : IExceptionFilter
{
    public void OnException(ExceptionContext context)
    {
        var exception = context.Exception;
        var conflict = exception is DbUpdateConcurrencyException ||
            exception is PostgresException { SqlState: "40001" or "40P01" } ||
            exception.InnerException is PostgresException { SqlState: "40001" or "40P01" };
        if (conflict)
            context.Result = new ConflictObjectResult(new { message = "This record changed. Reload it before trying again." });
        else if (exception is TransactionRuleException rule)
            context.Result = new ObjectResult(new { message = rule.Message }) { StatusCode = rule.StatusCode };
        else return;
        context.ExceptionHandled = true;
    }
}
