FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["Celticstech.csproj", "./"]
RUN dotnet restore "Celticstech.csproj"
COPY . .
RUN dotnet publish "Celticstech.csproj" -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
COPY --from=build /app/publish .

USER app

EXPOSE 8080
ENTRYPOINT ["dotnet", "Celticstech.dll"]