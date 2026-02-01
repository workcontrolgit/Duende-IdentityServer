FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:9.0 AS build
ARG TARGETARCH
WORKDIR /src
COPY ["src/DuendeIdentityServer.STS.Identity/DuendeIdentityServer.STS.Identity.csproj", "src/DuendeIdentityServer.STS.Identity/"]
COPY ["src/DuendeIdentityServer.Admin.EntityFramework.Shared/DuendeIdentityServer.Admin.EntityFramework.Shared.csproj", "src/DuendeIdentityServer.Admin.EntityFramework.Shared/"]
COPY ["src/DuendeIdentityServer.Shared/DuendeIdentityServer.Shared.csproj", "src/DuendeIdentityServer.Shared/"]
RUN dotnet restore -a $TARGETARCH "src/DuendeIdentityServer.STS.Identity/DuendeIdentityServer.STS.Identity.csproj"
COPY . .
WORKDIR "/src/src/DuendeIdentityServer.STS.Identity"
RUN dotnet build -a $TARGETARCH "DuendeIdentityServer.STS.Identity.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish -a $TARGETARCH "DuendeIdentityServer.STS.Identity.csproj" -c Release --no-restore -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENV ASPNETCORE_FORWARDEDHEADERS_ENABLED=true
ENTRYPOINT ["dotnet", "DuendeIdentityServer.STS.Identity.dll"]