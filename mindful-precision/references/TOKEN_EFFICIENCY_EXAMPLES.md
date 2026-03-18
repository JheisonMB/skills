# Token Efficiency — Examples

Scenarios showing how to minimize token usage without losing important context.

---

## Shell commands — filter output

### 1. Gradle build
```
❌ Wasteful:
gradle clean build
(outputs 200+ lines of dependency resolution, compilation, test results)

✅ Efficient:
gradle clean build 2>&1 | tail -n 15
(captures build result + any errors at the end)
```

### 2. Maven test
```
❌ Wasteful:
mvn test
(outputs hundreds of lines of download progress and test details)

✅ Efficient:
mvn test 2>&1 | grep -E "(BUILD|ERROR|FAIL|Tests run:)"
(captures only the summary and failures)
```

### 3. Docker logs
```
❌ Wasteful:
docker logs my-container
(could be thousands of lines)

✅ Efficient:
docker logs my-container 2>&1 | tail -n 30
(recent logs only — increase if needed)
```

### 4. npm install
```
❌ Wasteful:
npm install
(outputs every package resolved)

✅ Efficient:
npm install 2>&1 | tail -n 5
(just the summary: added X packages)
```

### 5. Subshell with exit code
```
✅ Efficient:
(gradle clean build > /tmp/build.log 2>&1); echo "EXIT:$?"
# If failed, then: tail -n 30 /tmp/build.log
(only reads the log if something went wrong)
```

---

## Responses — be lean

### 6. Don't re-explain code
```
❌ Wasteful:
"I've created the UserService class. The constructor
takes a UserRepository parameter for dependency injection.
The findById method returns a Mono<User> which is a
reactive type that..."

✅ Efficient:
"UserService created with findById and save methods.
Want me to add anything else?"
(the user can read the code — explain only if asked)
```

### 7. Skip obvious disclaimers
```
❌ Wasteful:
"Please note that this configuration may vary depending
on your specific environment, operating system version,
and installed dependencies. Make sure to test thoroughly
before deploying to production."

✅ Efficient:
(just don't say it — the user knows to test their code)
```

### 8. Go to the point
```
❌ Wasteful:
"Great question! Let me help you with that. So basically
what's happening here is that your application is experiencing
a common issue where..."

✅ Efficient:
"The error is because the reactive chain is missing
a subscribeOn scheduler for the blocking DB call.
Fix: wrap it in Mono.fromCallable().subscribeOn(Schedulers.boundedElastic())"
```

---

## The Rule in One Line

> Every token should earn its place. Filter commands, trim responses,
> skip what the user already knows.
