# Suggested actions from The Faction Group LLC Facebook videos

- **Source profile:** [https://www.facebook.com/profile.php?id=100091065962204](https://www.facebook.com/profile.php?id=100091065962204)
- **Collection date:** 2026-09-22
- **Coverage:** 424 reels indexed; 175 distinct actionable recommendations extracted after exact-repeat consolidation. 246 reels whose public descriptions contain no explicit action were excluded.
- **Method:** Actions come from the reels’ public written descriptions. Each entry keeps the operational context and links back to its source reel. Promotional calls to comment, follow, or send a direct message were excluded.
- **Reading guide:** Numbered entries are distinct recommendations; bullets state the concrete actions. Entries with multiple source links were repeated across reels.

## 1. Security, privacy, and identity

### 1.1. Authentication, authorization, and sessions

1. **logged in as your user without a password** ([video 1](https://www.facebook.com/reel/1792056885331354))
   - **Context:** An attacker just logged in as your user without a password. They set the session ID before your user authenticated.
   - **Suggested actions:**
     - Regenerate the session after every login using req.session.regenerate.
     - Regenerate on every privilege change.
     - Set Secure, HttpOnly, and SameSite flags.

2. **connected to your Redis instance and read every session token your app stores** ([video 1](https://www.facebook.com/reel/1094012279680098))
   - **Context:** An attacker just connected to your Redis instance and read every session token your app stores. Your AI set up Upstash and left the default connection open.
   - **Suggested actions:**
     - Enable ACL.
     - Restrict to only the commands your app uses.

3. **used a password reset link from four months ago** ([video 1](https://www.facebook.com/reel/1647704473579794))
   - **Context:** An attacker just used a password reset link from four months ago. The token still works.
   - **Suggested actions:**
     - Expire tokens in 15 minutes.
     - Invalidate after first use.

4. **called a private procedure in your tRPC router and got admin data** ([video 1](https://www.facebook.com/reel/1578665984057361))
   - **Context:** An attacker just called a private procedure in your tRPC router and got admin data. Your AI created the procedure without authorization middleware.
   - **Suggested actions:**
     - Verify every procedure has middleware.
     - Build from a protected base procedure so auth is the default.
     - Check ownership, not just identity.

5. **Every user connected to your app is receiving every other user's data in real time right…** ([video 1](https://www.facebook.com/reel/951764900667418))
   - **Context:** Every user connected to your app is receiving every other user's data in real time right now. Messages, transactions, account details to every browser tab.
   - **Suggested actions:**
     - Filter every subscription by the authenticated user.
     - Verify on the server, not the client.
     - Audit every subscription.

6. **promoted themselves to admin in your app by editing one field in a JWT** ([video 1](https://www.facebook.com/reel/1589567452713736))
   - **Context:** Someone just promoted themselves to admin in your app by editing one field in a JWT. Your server granted full access because your AI never verified the signature.
   - **Suggested actions:**
     - Verify the signature on every request.
     - Validate expiration and issuer.
     - Use Clerk's server-side SDK.

7. **grabbed your Google Login authorization code on a mobile network and logged in as your u…** ([video 1](https://www.facebook.com/reel/1055631623841013))
   - **Context:** An attacker just grabbed your Google Login authorization code on a mobile network and logged in as your user. State stops forgery.
   - **Suggested actions:**
     - Generate a code verifier.
     - Hash it as the challenge.
     - Send the original with the token request.
     - Implement both layers.

8. **stored your authentication token in localStorage** ([video 1](https://www.facebook.com/reel/1679814123086008))
   - **Context:** Your AI stored your authentication token in localStorage. Any script on your page can steal it and log in as your user.
   - **Suggested actions:**
     - Move tokens to httpOnly cookies JavaScript cannot touch.
     - Short expiration with refresh rotation.
     - Token revocation when a user's security state changes.
     - Stop leaving it on the counter.

9. **added a chat widget to your site** ([video 1](https://www.facebook.com/reel/1364566092504182))
   - **Context:** You added a chat widget to your site. It can read every password your users type on every page.
   - **Suggested actions:**
     - Audit every third-party script.
     - Remove them from login, checkout, and admin pages.
     - Implement a Content Security Policy.

10. **picked your auth provider because it was free** ([video 1](https://www.facebook.com/reel/1667330044883649))
   - **Context:** You picked your auth provider because it was free. Your enterprise buyer just walked.
   - **Suggested actions:**
     - Evaluate your auth provider for enterprise readiness before your biggest deal walks.

11. **A user logged in six months ago** ([video 1](https://www.facebook.com/reel/1619309196387343))
   - **Context:** A user logged in six months ago. They lost their laptop at a coffee shop three months ago.
   - **Suggested actions:**
     - Close the doors it left open.

12. **Your security kicks users out every 15 minutes** ([video 1](https://www.facebook.com/reel/2049620045649534))
   - **Context:** Your security kicks users out every 15 minutes. Even when they are working.
   - **Suggested actions:**
     - Track meaningful actions, warn before the kill, and preserve state on re-login.

13. **added Google Sign-In** ([video 1](https://www.facebook.com/reel/1665262511220886))
   - **Context:** Your AI added Google Sign-In. It did not handle the token lifecycle.
   - **Suggested actions:**
     - Silently refresh, gracefully fail, and rotate tokens.

14. **The vulnerability that lets anyone forge a token exists in your stack right now** ([video 1](https://www.facebook.com/reel/1550107533133417))
   - **Context:** The vulnerability that lets anyone forge a token exists in your stack right now.
   - **Suggested actions:**
     - Check the algorithm.

15. **works in the demo** ([video 1](https://www.facebook.com/reel/997737589882253))
   - **Context:** Your app works in the demo. It works when you show your friends.
   - **Suggested actions:**
     - Add the boring stuff — error messages, loading states, password reset A demo impresses people.
     - Ship the product.

16. **Vibe-coded apps have one thing in common** ([video 1](https://www.facebook.com/reel/948192511365354))
   - **Context:** Vibe-coded apps have one thing in common. The auth is broken.
   - **Suggested actions:**
     - Never roll your own — use Clerk, Supabase Auth, or Auth0.
     - Test the logout — log in, copy URL, log out, paste it back.

17. **Clerk or Auth0** ([video 1](https://www.facebook.com/reel/2932070533814732))
   - **Context:** Clerk or Auth0. They solve completely different problems.
   - **Suggested actions:**
     - Match the auth to the customer.

18. **added Sign in with Google** ([video 1](https://www.facebook.com/reel/2313395599446596))
   - **Context:** You added Sign in with Google. Your AI left the redirect wide open.
   - **Suggested actions:**
     - Lock redirect URIs to exact registered URLs.
     - Enforce a state parameter on every OAuth request.
     - Scope token permissions to the minimum your app needs.
     - Make sure it only works for you.

### 1.2. Application and API security

1. **accessed every protected page in your app without logging in** ([video 1](https://www.facebook.com/reel/2058292508383948))
   - **Context:** An attacker just accessed every protected page in your app without logging in. Your Next.js middleware checks authentication.
   - **Suggested actions:**
     - Verify the matcher covers every route.
     - Test with path variations.
     - Add server-side checks independent of middleware.

2. **embedded your entire app inside their website** ([video 1](https://www.facebook.com/reel/1402791905301675))
   - **Context:** An attacker just embedded your entire app inside their website. Your users click buttons on your app while looking at the attacker's page.
   - **Suggested actions:**
     - Add X-Frame-Options DENY and Content-Security-Policy frame-ancestors.

3. **used your login page to send your users to a phishing site** ([video 1](https://www.facebook.com/reel/2425501161312192))
   - **Context:** An attacker just used your login page to send your users to a phishing site. The URL looks like your domain.
   - **Suggested actions:**
     - Validate redirects against an allowlist.
     - Reject encoded variants.
     - Audit every redirect in your auth flow.

4. **downloaded your entire API schema** ([video 1](https://www.facebook.com/reel/1387153369673019))
   - **Context:** An attacker just downloaded your entire API schema. Every query, mutation, type, and relationship.
   - **Suggested actions:**
     - Disable introspection in production.
     - Enforce query depth limits.
     - Disable field suggestions in error messages.
     - An attacker should never see it.

5. **triggered your Vercel scheduled task by guessing the URL** ([video 1](https://www.facebook.com/reel/968377782974939))
   - **Context:** Someone just triggered your Vercel scheduled task by guessing the URL. Database cleanup, email sends, subscription renewals, all on demand.
   - **Suggested actions:**
     - Verify the authorization secret.
     - Set it in your environment variables.
     - Add rate limiting.
     - Lock it down.

6. **An attacker sent a phishing email from your domain** ([video 1](https://www.facebook.com/reel/2147725646139919))
   - **Context:** An attacker sent a phishing email from your domain. Your own email system.
   - **Suggested actions:**
     - Sanitize every input.
     - Render as text, never HTML.
     - Test with angle brackets in every field.

7. **skipped your entire form and sent raw data to your API** ([video 1](https://www.facebook.com/reel/1528262642319949))
   - **Context:** An attacker just skipped your entire form and sent raw data to your API. Empty strings, negative prices, garbage in every field.
   - **Suggested actions:**
     - Run Zod on the server.
     - Reject unexpected fields.
     - Test every route without the form.

8. **Your server just charged the same card twice, provisioned the same user twice, sent the…** ([video 1](https://www.facebook.com/reel/1447442433949692))
   - **Context:** Your server just charged the same card twice, provisioned the same user twice, sent the same email twice. Every webhook signature was valid.
   - **Suggested actions:**
     - Store every event ID before processing.
     - Set a 24-hour replay window.
     - Return success for duplicates.
     - Idempotency proves you only acted once.

9. **typed a crafted string into your search field and your database returned every user's cr…** ([video 1](https://www.facebook.com/reel/2107222506657260))
   - **Context:** An attacker just typed a crafted string into your search field and your database returned every user's credentials. Your AI dropped into raw SQL and removed every protection Prisma provides.
   - **Suggested actions:**
     - Use the ORM's safe raw query method.
     - Validate every input.

10. **moved to a VPS for more control** ([video 1](https://www.facebook.com/reel/2312752866139159))
   - **Context:** You moved to a VPS for more control. You left the front door wide open.
   - **Suggested actions:**
     - Lock it down before someone else walks in.

11. **Your API is configured to accept requests from any origin with credentials** ([video 1](https://www.facebook.com/reel/2365569217597394))
   - **Context:** Your API is configured to accept requests from any origin with credentials. That means any website can make authenticated requests as your users.
   - **Suggested actions:**
     - Hardcode an origin allowlist.
     - Lock down session cookies.
     - Restrict methods and headers per endpoint.

12. **agent fetches any URL a user submits** ([video 1](https://www.facebook.com/reel/1086129644102022))
   - **Context:** Your AI agent fetches any URL a user submits. An attacker just used it to hit your cloud credential service from inside your network and walked away with full access.
   - **Suggested actions:**
     - Restrict outbound fetches to approved domains.
     - Pin URL resolution so redirects cannot change the target.
     - Make sure it only talks to who you approve.

13. **Your login endpoint received 14,000 requests last night** ([video 1](https://www.facebook.com/reel/1075280715057265))
   - **Context:** Your login endpoint received 14,000 requests last night. None of them were your users.
   - **Suggested actions:**
     - Configure it.

14. **Seven out of my last ten audits had API keys committed to GitHub** ([video 1](https://www.facebook.com/reel/3189540921436256))
   - **Context:** Seven out of my last ten audits had API keys committed to GitHub. Stripe secret keys.
   - **Suggested actions:**
     - Do not let yours be next.

15. **built your app in a weekend** ([video 1](https://www.facebook.com/reel/1529005592240625))
   - **Context:** Your AI built your app in a weekend. A security auditor would shut it down by Monday.
   - **Suggested actions:**
     - Fix error handling, set security headers, and add input validation on every endpoint before someone tests what your AI left open.

16. **loaded scripts from 14 domains** ([video 1](https://www.facebook.com/reel/1554900586357786))
   - **Context:** Your AI loaded scripts from 14 domains. Every one runs code in your users' browsers.
   - **Suggested actions:**
     - Add CSP headers, audit every external resource, and report before enforcing.
     - Lock it down.

17. **built an API that trusts every request it receives** ([video 1](https://www.facebook.com/reel/2270069893762759))
   - **Context:** Your AI built an API that trusts every request it receives. That is AI-Directed orchestration.
   - **Suggested actions:**
     - Validate every input, sanitize every string, and track request patterns.
     - Validate everything.

18. **Your supply chain is not just npm packages anymore** ([video 1](https://www.facebook.com/reel/2182534599192615))
   - **Context:** Your supply chain is not just npm packages anymore. Every prompt and skill file your AI touches.
   - **Suggested actions:**
     - Fix the feed.

19. **The first time I ever ran OWASP ZAP on one of my own apps** ([video 1](https://www.facebook.com/reel/2510374126065909))
   - **Context:** The first time I ever ran OWASP ZAP on one of my own apps. In an app I thought was ready to ship.
   - **Suggested actions:**
     - Scan yourself before someone else does.

20. **Your frontend is a display layer, not a trust layer** ([video 1](https://www.facebook.com/reel/1016536517435175))
   - **Context:** Your frontend is a display layer, not a trust layer.
   - **Suggested actions:**
     - Move business logic, validation, and secrets to the backend.

21. **Same API key for six months** ([video 1](https://www.facebook.com/reel/27211794388510360))
   - **Context:** Same API key for six months. Infinite blast radius.
   - **Suggested actions:**
     - Fix it.

22. **847 dependencies** ([video 1](https://www.facebook.com/reel/1339298594739587))
   - **Context:** 10 minutes saves everything.
   - **Suggested actions:**
     - Run npm audit today.
     - Lock your versions.

23. **70% of Lovable apps shipped with row-level security disabled** ([video 1](https://www.facebook.com/reel/2216767089061874))
   - **Context:** 70% of Lovable apps shipped with row-level security disabled. Any user can read any other user's data.
   - **Suggested actions:**
     - Ship the lock, not just the storefront.

24. **accept webhooks from Stripe without verifying the signature** ([video 1](https://www.facebook.com/reel/940563205038762))
   - **Context:** You accept webhooks from Stripe without verifying the signature. Anyone can send your server a fake payment confirmation.
   - **Suggested actions:**
     - Signature verification on every webhook.
     - Idempotency to prevent replay attacks.
     - Endpoint protection with non-guessable URLs.

25. **shipped your web app as a mobile app** ([video 1](https://www.facebook.com/reel/1595191228977675))
   - **Context:** You shipped your web app as a mobile app. Every API key is visible in local storage.
   - **Suggested actions:**
     - Secrets in native keychain.
     - Certificate pinning on every call.
     - Deep link validation on every callback.

26. **Your browser is protecting your users right now** ([video 1](https://www.facebook.com/reel/2178711406213318))
   - **Context:** Your browser is protecting your users right now. Trust the browser.
   - **Suggested actions:**
     - Configure the headers.

27. **One kid with a laptop can take your entire product offline right now** ([video 1](https://www.facebook.com/reel/1355640899480321))
   - **Context:** One kid with a laptop can take your entire product offline right now. Not a nation-state hacker.
   - **Suggested actions:**
     - Fix that today by configuring a web application firewall and DDoS protection.

### 1.3. Data protection and tenant isolation

1. **Every time a new client signs up, your developer forks the entire repository** ([video 1](https://www.facebook.com/reel/1034772759389090))
   - **Context:** Every time a new client signs up, your developer forks the entire repository. Eleven sets of bugs.
   - **Suggested actions:**
     - Feature flags per tenant.
     - Configuration inheritance with overrides.
     - Tenant-aware routing at the boundary.

2. **Your first enterprise customer sent a procurement checklist** ([video 1](https://www.facebook.com/reel/1052196023970495))
   - **Context:** Your first enterprise customer sent a procurement checklist. Line one: do you support SSO?
   - **Suggested actions:**
     - Learn SAML.
     - Build tenant-specific configuration.

3. **Customer A logged in and saw customer B's data** ([video 1](https://www.facebook.com/reel/1036462775424400))
   - **Context:** Customer A logged in and saw customer B's data. The technical fix takes an hour.
   - **Suggested actions:**
     - Build tenant isolation as a business requirement from day one.

4. **Three questions every builder should answer before launch** ([video 1](https://www.facebook.com/reel/2043771703158078))
   - **Context:** Do you have cyber liability insurance. Have you read your platform terms.
   - **Suggested actions:**
     - Three questions every builder should answer before launch.

### 1.4. Supply chain and client security

1. **deleted the app six months ago** ([video 1](https://www.facebook.com/reel/1756523849021183))
   - **Context:** You deleted the app six months ago. The DNS record is still there.
   - **Suggested actions:**
     - Scan your records.
     - Audit your cookie scope.

## 2. Production engineering and DevOps

### 2.1. Deployment, environments, and release control

1. **pushed 47 files to production in one commit** ([video 1](https://www.facebook.com/reel/1525983845996360))
   - **Context:** Your AI pushed 47 files to production in one commit. One of them broke your payment flow.
   - **Suggested actions:**
     - Build the gate.

2. **Every push goes straight to production** ([video 1](https://www.facebook.com/reel/2604460696637879))
   - **Context:** Every push goes straight to production. One bad merge and your customers see the bug first.
   - **Suggested actions:**
     - Build staging, gate production behind tests, and implement one-click rollback.
     - Stop shipping on a prayer.

3. **AI breaks traditional CI/CD** ([video 1](https://www.facebook.com/reel/958772710313057))
   - **Context:** AI breaks traditional CI/CD.
   - **Suggested actions:**
     - Replace assertions with evals, add cost checks, and gate on canary quality.

4. **Ship to 5% first** ([video 1](https://www.facebook.com/reel/1806072793688131))
   - **Context:** Promote or roll back.
   - **Suggested actions:**
     - Ship to 5% first.
     - Never break prod for everyone.

5. **Layer 5 of 13!** ([video 1](https://www.facebook.com/reel/972879092124709))
   - **Context:** Layer 5 of 13! 🙏 That's not a deployment strategy.
   - **Suggested actions:**
     - Push to main.

6. **Hit deploy** ([video 1](https://www.facebook.com/reel/923276644075289))
   - **Context:** Hit deploy again. No idea what changed.
   - **Suggested actions:**
     - Know your rollback — one click, under 60 seconds, before you need it Every deploy should be boring.
     - Ship with confidence, not crossed fingers.

7. **Deploy** ([video 1](https://www.facebook.com/reel/1303555605054964))
   - **Context:** Nobody knows why. That's deployment roulette 👆
   - **Suggested actions:**
     - Deploy again.

8. **Dev, staging, production, all in the same place: your laptop** ([video 1](https://www.facebook.com/reel/2453888091739501))
   - **Context:** Dev, staging, production, all in the same place: your laptop. You are testing and breaking everything live.
   - **Suggested actions:**
     - Separate development, staging, and production environments.
     - Do not test changes in production.

### 2.2. Reliability, observability, and incident readiness

1. **just showed a user your database name, your server file path, and the query that failed** ([video 1](https://www.facebook.com/reel/1884884205810255))
   - **Context:** Your app just showed a user your database name, your server file path, and the query that failed. They were not trying to hack you.
   - **Suggested actions:**
     - Separate error responses by environment.
     - Route every error to logging, not the screen.
     - Build custom error pages that reveal nothing.
     - Do not let the bug report write itself.

2. **Your user just saw your database password on their screen** ([video 1](https://www.facebook.com/reel/1836412080968054))
   - **Context:** Your user just saw your database password on their screen. Your app crashed and dumped a raw stack trace with your connection string, your framework version, and the exact line that failed.
   - **Suggested actions:**
     - Build a logging pipeline.
     - Fix it today.

3. **went down and your customers think you stole their money** ([video 1](https://www.facebook.com/reel/1342526424150654))
   - **Context:** Your app went down and your customers think you stole their money. Six hours of downtime.
   - **Suggested actions:**
     - Build a status page on a separate host, a maintenance announcement system, and an incident communication workflow.

4. **Your first customer dispute will freeze your Stripe account** ([video 1](https://www.facebook.com/reel/1028616903464352))
   - **Context:** Your first customer dispute will freeze your Stripe account. Not some of your funds.
   - **Suggested actions:**
     - Publish a refund policy, configure chargeback alerts, and build a dispute response workflow before your first claim hits.

5. **Your first production incident is coming** ([video 1](https://www.facebook.com/reel/1985041215473267))
   - **Context:** Your first production incident is coming. That is not the problem.
   - **Suggested actions:**
     - Build the post-mortem template, enforce the 48-hour review, and maintain the incident library.

6. **Your monitoring says green** ([video 1](https://www.facebook.com/reel/3569849013165715))
   - **Context:** Your monitoring says green. Your support inbox says twelve things are broken.
   - **Suggested actions:**
     - Categorize tickets by root cause.

7. **Your error tracker catches errors your code throws** ([video 1](https://www.facebook.com/reel/2531191280659185), [video 2](https://www.facebook.com/reel/1385474746968675))
   - **Context:** Your error tracker catches errors your code throws. It cannot catch the ones your code swallows.
   - **Suggested actions:**
     - Monitor what your tools were never built to see.

### 2.3. Performance, scaling, and infrastructure

1. **They call me grandpa AI in the comments** ([video 1](https://www.facebook.com/reel/2893555590982656))
   - **Context:** They call me grandpa AI in the comments. Then they copy every prompt I post.
   - **Suggested actions:**
     - Pick one system you are renting.
     - Build the replacement.

2. **Your database has been doing a full table scan on every request since launch** ([video 1](https://www.facebook.com/reel/4384241861893228))
   - **Context:** Your database has been doing a full table scan on every request since launch. You did not notice until your hosting provider throttled you.
   - **Suggested actions:**
     - Add indexes.
     - Restrict query fields.
     - Enable slow query logging.
     - Fix it before your hosting provider fixes it for you.

3. **have paid your payment processor $30,000** ([video 1](https://www.facebook.com/reel/1057687353570941))
   - **Context:** You have paid your payment processor $30,000. It has processed zero dollars for you.
   - **Suggested actions:**
     - Stop activating expensive infrastructure before demand forces you to.
     - Sandbox it.
     - Demo it.
     - Sell it.

4. **Your serverless function times out at 60 seconds** ([video 1](https://www.facebook.com/reel/1372932234763234))
   - **Context:** Your serverless function times out at 60 seconds. The job takes 3 minutes.
   - **Suggested actions:**
     - Identify what does not fit, containerize the heavy workloads, and route by type.
     - Add a lane.

5. **The scaling decision tree has three branches** ([video 1](https://www.facebook.com/reel/1021530490331538))
   - **Context:** The scaling decision tree has three branches.
   - **Suggested actions:**
     - Check them in order or spend tens of thousands solving a problem that costs nothing to fix.

6. **Three deployment models** ([video 1](https://www.facebook.com/reel/1333468615653132))
   - **Context:** Three deployment models. Three cost curves.
   - **Suggested actions:**
     - Match the hosting to the stage.

7. **Your database might not be overloaded** ([video 1](https://www.facebook.com/reel/1549090670131841))
   - **Context:** Your database might not be overloaded. Your connections might be.
   - **Suggested actions:**
     - Check the foundation first.

8. **Serverless Postgres or serverless MySQL** ([video 1](https://www.facebook.com/reel/1041906648520874))
   - **Context:** Serverless Postgres or serverless MySQL. Neon or PlanetScale?
   - **Suggested actions:**
     - Choose the engine you know.

9. **added indexes and your app is still slow** ([video 1](https://www.facebook.com/reel/1797202828391694))
   - **Context:** You added indexes and your app is still slow.
   - **Suggested actions:**
     - Stop guessing.
     - Start measuring.

10. **is fast in Virginia** ([video 1](https://www.facebook.com/reel/2767946723585036))
   - **Context:** Your app is fast in Virginia. Your users are in Singapore.
   - **Suggested actions:**
     - Fix it with multi-region.

11. **Your database has two versions of every record right now** ([video 1](https://www.facebook.com/reel/3116953925164946))
   - **Context:** Your database has two versions of every record right now. Your app is showing users the wrong one.
   - **Suggested actions:**
     - Read-after-write routing.
     - Replica lag monitoring.
     - Conflict resolution on concurrent writes.

12. **Not Everything Should Be Cached** ([video 1](https://www.facebook.com/reel/1367605128637879))
   - **Context:** You added a cache to fix a slow page. Now users see data from yesterday.
   - **Suggested actions:**
     - Not Everything Should Be Cached.

13. **Most people think full-stack means frontend and backend** ([video 1](https://www.facebook.com/reel/955038200490096))
   - **Context:** Most people think full-stack means frontend and backend. That is 2 layers out of
   - **Suggested actions:**
     - Audit the full production stack and add the missing layers before scaling beyond a prototype.

### 2.4. Architecture, APIs, and databases

1. **Everyone asked the same question this week** ([video 1](https://www.facebook.com/reel/1832879954747792))
   - **Context:** Everyone asked the same question this week. That is great for an $8 billion law firm.
   - **Suggested actions:**
     - Stop handing them to a company building its IPO on top of them.

2. **Your user's full database record is in their browser right now** ([video 1](https://www.facebook.com/reel/1050773241112240))
   - **Context:** Your user's full database record is in their browser right now. Your React Server Component displays three fields.
   - **Suggested actions:**
     - Select only the fields the component renders.
     - Audit every Server Component that receives database results.

3. **A user just queried your Neon database and downloaded every other user's records** ([video 1](https://www.facebook.com/reel/1594456052713278))
   - **Context:** A user just queried your Neon database and downloaded every other user's records. Row Level Security was never turned on.
   - **Suggested actions:**
     - Enable RLS on every table.
     - Verify with a second account.

4. **CodeRabbit reviewed your code and found zero issues** ([video 1](https://www.facebook.com/reel/1854059445608064))
   - **Context:** CodeRabbit reviewed your code and found zero issues. Your API endpoint still accepts every field in the request body.
   - **Suggested actions:**
     - Whitelist allowed fields.
     - Separate user and admin endpoints.
     - Test by sending fields that should be rejected.

5. **Your API uses the user ID in the URL to load their data** ([video 1](https://www.facebook.com/reel/2288815945305819))
   - **Context:** Your API uses the user ID in the URL to load their data. Change the number.
   - **Suggested actions:**
     - Verify ownership on every request.
     - Replace sequential IDs with UUIDs.
     - Audit every endpoint that takes an ID.
     - Your API should not trust the URL.
     - It should trust the session.

6. **AWS just killed Bedrock Agents** ([video 1](https://www.facebook.com/reel/1611598323784719))
   - **Context:** AWS just killed Bedrock Agents. Renamed it to Classic.
   - **Suggested actions:**
     - Abstraction layer between your app and any vendor SDK.
     - BAA audit after any provider migration.

7. **Someone sent a forged request to your API last Tuesday** ([video 1](https://www.facebook.com/reel/908011369035276))
   - **Context:** Someone sent a forged request to your API last Tuesday. Your server processed it, no questions asked.
   - **Suggested actions:**
     - Request signing on every mutating endpoint.
     - API versioning from day one.
     - Sunset headers with deprecation monitoring.

8. **added one column to your database for one client** ([video 1](https://www.facebook.com/reel/1385070490426483))
   - **Context:** You added one column to your database for one client. Every other client's queries slowed down by 40%.
   - **Suggested actions:**
     - Per-tenant schema extensions.
     - Tenant-isolated compute.
     - Tenant-scoped migrations.

9. **built your database** ([video 1](https://www.facebook.com/reel/1780963386394170))
   - **Context:** Your AI built your database. Your app is live.
   - **Suggested actions:**
     - It never planned for the day you have to change it.
     - Write migrations that add before they remove, build the rollback before the migration, and test it on staging first.

10. **Your database changed** ([video 1](https://www.facebook.com/reel/2460532837790078))
   - **Context:** Your database changed. Your search index shows old data.
   - **Suggested actions:**
     - Implement Change Data Capture.
     - Route events by type.

11. **The database you started with is not the one you need** ([video 1](https://www.facebook.com/reel/1034693765695277), [video 2](https://www.facebook.com/reel/1371732991548466))
   - **Context:** The database you started with is not the one you need. Staying too long costs hours.
   - **Suggested actions:**
     - When the math says go, go decisively.

12. **Read-write ratio determines the architecture** ([video 1](https://www.facebook.com/reel/1714419109891247), [video 2](https://www.facebook.com/reel/2606001843149666))
   - **Context:** Read-write ratio determines the architecture. Schema change strategy determines survivability.
   - **Suggested actions:**
     - Choose the database by the workload.

13. **Convex is blowing up** ([video 1](https://www.facebook.com/reel/1422614439630749))
   - **Context:** Convex is blowing up. Postgres has been running for forty years.
   - **Suggested actions:**
     - Pick the tradeoff you can live with.

14. **Prisma protects you from the database** ([video 1](https://www.facebook.com/reel/876961368790886))
   - **Context:** Prisma protects you from the database. Drizzle trusts you with it.
   - **Suggested actions:**
     - Match the ORM to the team.

15. **Half of the questions in my DMs are about this topic** ([video 1](https://www.facebook.com/reel/1001744732665130))
   - **Context:** Half of the questions in my DMs are about this topic. Supabase or Firebase.
   - **Suggested actions:**
     - Stop comparing features.
     - Start comparing futures.

16. **45-second request** ([video 1](https://www.facebook.com/reel/1312427314398219))
   - **Context:** User clicks again.
   - **Suggested actions:**
     - Fix it with background architecture.

17. **50 users** ([video 1](https://www.facebook.com/reel/993121743707149))
   - **Context:** 20 database connections.
   - **Suggested actions:**
     - Fix it with connection pooling.

18. **Your database doesn't have to live with your app** ([video 1](https://www.facebook.com/reel/1463566825798967))
   - **Context:** Neon gives you serverless Postgres with Git-style branching. Total Game changer.
   - **Suggested actions:**
     - Your database doesn't have to live with your app.

19. **works great** ([video 1](https://www.facebook.com/reel/1722520405767028))
   - **Context:** Your app works great. Then the API changes.
   - **Suggested actions:**
     - Build a fallback — anything is better than a blank screen and silence.

20. **built Firebase Cloud Functions with the Admin SDK** ([video 1](https://www.facebook.com/reel/898221866438953))
   - **Context:** Your AI built Firebase Cloud Functions with the Admin SDK. The Admin SDK bypasses every security rule in your database.
   - **Suggested actions:**
     - Validate every input before it hits the database.
     - Scope every query to the authenticated user.
     - Audit the gap between what your functions can access and what they should.

21. **added one endpoint to your API last week** ([video 1](https://www.facebook.com/reel/1506716497879429))
   - **Context:** You added one endpoint to your API last week. It broke three integrations you did not know existed.
   - **Suggested actions:**
     - Run both.
     - Set a sunset date.
     - Ship v2 before v1 buries you.

22. **Your API is simultaneously a security surface, a product surface, and a contract surface…** ([video 1](https://www.facebook.com/reel/1485127020308161))
   - **Context:** Your API is simultaneously a security surface, a product surface, and a contract surface. This is the business lens on API design.
   - **Suggested actions:**
     - Implement API versioning with /v1/ prefix.
     - Create an API changelog and public documentation page.

## 3. AI engineering and agent operations

### 3.1. Model selection, routing, and cost control

1. **Stop eyeballing your AI outputs** ([video 1](https://www.facebook.com/reel/1785662122416602))
   - **Context:** Model-as-judge scoring, in your CI pipeline, makes quality measurable.
   - **Suggested actions:**
     - Stop eyeballing your AI outputs.

2. **AI Provider Secret!** ([video 1](https://www.facebook.com/reel/1307206264945068))
   - **Context:** AI Provider Secret! Stack all three and watch your AI bill collapse.
   - **Suggested actions:**
     - Prompt caching + plus batch APIs + plus model tiering.

### 3.2. Agents, orchestration, and tool design

1. **NIST says most agents run on borrowed credentials** ([video 1](https://www.facebook.com/reel/1545051350723921))
   - **Context:** NIST says most agents run on borrowed credentials. Every agent needs its own identity.
   - **Suggested actions:**
     - Short-lived keys.
     - Approval gates before production.
     - Separate logs per session.

2. **put your database credentials in a Next.js Server Action** ([video 1](https://www.facebook.com/reel/1362878112226436))
   - **Context:** Your AI put your database credentials in a Next.js Server Action. The build process shipped them to every user's browser.
   - **Suggested actions:**
     - Install server-only to prevent server code from entering the client bundle.
     - Separate server and client files.
     - Scan the production build for leaked secrets.

3. **wrapped a CLI tool in an MCP server** ([video 1](https://www.facebook.com/reel/1120583804254330))
   - **Context:** You wrapped a CLI tool in an MCP server. Your agent now runs slower, costs more, and does less.
   - **Suggested actions:**
     - Audit your MCP servers.
     - Measure the cost.

4. **said yes to every client request for 18 months** ([video 1](https://www.facebook.com/reel/1441518108033051))
   - **Context:** You said yes to every client request for 18 months. Your product no longer ships without breaking something.
   - **Suggested actions:**
     - Create a customization cost model before writing code.
     - Prefer configuration to client-specific code branches.
     - Productize a customization once three clients request it.

5. **is running on six-month-old instructions** ([video 1](https://www.facebook.com/reel/2844157235957543))
   - **Context:** Your AI is running on six-month-old instructions. That is why it is getting worse, not better.
   - **Suggested actions:**
     - Clear stale MCPs, instruction files, skills, and automations every 90–100 days.
     - Rebuild the AI context stack cleanly for the current model.

6. **agent forgot what it was doing halfway through the job** ([video 1](https://www.facebook.com/reel/3322016041333382))
   - **Context:** Your AI agent forgot what it was doing halfway through the job. Step one was clean.
   - **Suggested actions:**
     - Build a state file, decompose tasks into chunks, and validate between every step.

7. **built the app** ([video 1](https://www.facebook.com/reel/1023018453988059))
   - **Context:** Your AI built the app. Who supports it at 2 AM?
   - **Suggested actions:**
     - Build three tiers of support, automated resolution, assisted triage, incident response.

8. **Your user reported a bug** ([video 1](https://www.facebook.com/reel/1720223808991351))
   - **Context:** Your user reported a bug. They said it just stopped working.
   - **Suggested actions:**
     - Add session replay.
     - Flag rage clicks.
     - Stop asking.
     - Start watching.

9. **We saved a client $14K/month** ([video 1](https://www.facebook.com/reel/1503671191372822))
   - **Context:** We saved a client $14K/month. We identified the 40% of their SaaS stack that AI can replace natively.
   - **Suggested actions:**
     - Stop renting.
     - Start owning.

10. **have 47 skills loaded into your AI right now** ([video 1](https://www.facebook.com/reel/1081797247578287))
   - **Context:** You have 47 skills loaded into your AI right now. Half of them were written for a model that no longer exists.
   - **Suggested actions:**
     - Audit your skills.

11. **Two multi-agent patterns** ([video 1](https://www.facebook.com/reel/27502024062768390))
   - **Context:** Two multi-agent patterns. Earn conductor with data.
   - **Suggested actions:**
     - Start with orchestrator.

### 3.3. AI quality, testing, and secure delivery

1. **We watched thousands of builders use our products for sixty days** ([video 1](https://www.facebook.com/reel/28139612022347541))
   - **Context:** We watched thousands of builders use our products for sixty days. The data told us what to build next.
   - **Suggested actions:**
     - Use community activity, website traffic, and purchase data to decide what to build next.
     - Create a closed loop in which an audit finds the issue, a skill fixes it, and a rerun verifies the result.

2. **built it** ([video 1](https://www.facebook.com/reel/855464720836541))
   - **Context:** You built it. Months of engineering.
   - **Suggested actions:**
     - While you were engineering the product, you should have been engineering the audience.
     - By launch day you should already have proof that people want what you built.

3. **built your whole product in one weekend** ([video 1](https://www.facebook.com/reel/1063966076081866))
   - **Context:** You built your whole product in one weekend. You have been debugging it for three months.
   - **Suggested actions:**
     - Stop chasing individual fixes.
     - Map the whole picture first.

4. **2,000 builders asked us to look at their apps** ([video 1](https://www.facebook.com/reel/1025042836945101))
   - **Context:** 2,000 builders asked us to look at their apps. The same three things were broken in almost every single one.
   - **Suggested actions:**
     - Close these three gaps.

### 3.4. AI context, memory, and data readiness

1. **39% say integration is their AI barrier** ([video 1](https://www.facebook.com/reel/1405839527431055))
   - **Context:** 39% say integration is their AI barrier.
   - **Suggested actions:**
     - Separate tools that don't talk = friction tax 🔌👆 DigitalTransformation.

## 4. AI adoption, workforce, and change

### 4.1. Readiness, governance, and ownership

1. **cannot learn to shoot content after your product** ([video 1](https://www.facebook.com/reel/1029396303253211))
   - **Context:** You cannot learn to shoot content after your product. You are already too late.
   - **Suggested actions:**
     - Start talking now.
     - Start badly.
     - Start today.

2. **A plumber asked me what AI tool to start with** ([video 1](https://www.facebook.com/reel/4133185683638660))
   - **Context:** A plumber asked me what AI tool to start with. My answer: none.
   - **Suggested actions:**
     - Start with an AI conversation.

3. **strategy is backwards** ([video 1](https://www.facebook.com/reel/934006762796573))
   - **Context:** Your AI strategy is backwards. Every company I consult with wants to start with the technology.
   - **Suggested actions:**
     - Start with the destination, then pick the vehicle.
     - Write down the 3 tasks that eat the most time in your week.
     - Start there.

4. **Amazon AI is coming for your business in 3 waves** ([video 1](https://www.facebook.com/reel/1852583362092462))
   - **Context:** Amazon AI is coming for your business in 3 waves. Most SMBs won't survive the third.
   - **Suggested actions:**
     - Don't be the taxi company polishing your yellow medallion while Uber launches.
     - Start your AI readiness now.

5. **AI readiness isn't about slowing teams down** ([video 1](https://www.facebook.com/reel/937654429265617))
   - **Context:** AI readiness isn't about slowing teams down. It's how you move fast without breaking things.
   - **Suggested actions:**
     - One clear business problem.
     - One owner.
     - One low-risk experiment.

6. **Most companies don't fail at AI because they move too fast** ([video 1](https://www.facebook.com/reel/1606391893836778))
   - **Context:** Most companies don't fail at AI because they move too fast. They fail because they wait to feel "ready." Readiness isn't delay.
   - **Suggested actions:**
     - Pick one use case.
     - Start this week.

### 4.2. Team adoption, training, and change management

1. **Every AI ROI model you've seen is lying to you** ([video 1](https://www.facebook.com/reel/1510774233926691))
   - **Context:** Every AI ROI model you've seen is lying to you. They assume 100% adoption.
   - **Suggested actions:**
     - Stop measuring it wrong.

2. **When staff owns the AI problem, it gets fixed** ([video 1](https://www.facebook.com/reel/1463597421315422))
   - **Context:** When staff owns the AI problem, it gets fixed. When management owns it, staff resist.
   - **Suggested actions:**
     - Run a hackathon.

3. **Your team doesn't resist AI** ([video 1](https://www.facebook.com/reel/1960271527952851))
   - **Context:** Your team doesn't resist AI. They resist being told their workflow is wrong by someone who's never done their job.
   - **Suggested actions:**
     - Stop pushing.
     - Start modeling.
     - Use AI visibly.

4. **have 14 days** ([video 1](https://www.facebook.com/reel/984891527453132))
   - **Context:** You have 14 days. We tracked 40+ AI rollouts.
   - **Suggested actions:**
     - Compress or lose.

### 4.3. Personal and executive productivity

1. **Your customer just paid you** ([video 1](https://www.facebook.com/reel/1058668569957015))
   - **Context:** Your customer just paid you. And they think you are a scam.
   - **Suggested actions:**
     - Set up SPF, DKIM, a dedicated sending domain, and delivery monitoring.

2. **Your revenue is disappearing every month and you cannot see it** ([video 1](https://www.facebook.com/reel/1530544154748501))
   - **Context:** Your revenue is disappearing every month and you cannot see it. Credit cards expire.
   - **Suggested actions:**
     - Build a retry schedule, a failed payment email sequence, and a grace period before your MRR bleeds out.

3. **Every morning before I open email, before Slack, before I talk to anyone, my AI gives me…** ([video 1](https://www.facebook.com/reel/1641258503970712))
   - **Context:** Every morning before I open email, before Slack, before I talk to anyone, my AI gives me a briefing. It changed how I run my entire day and business.
   - **Suggested actions:**
     - Create an AI morning briefing before opening email or Slack.
     - Pull the calendar with context on every meeting, including participants, the previous discussion, and preparation needs.
     - Check priorities against the schedule and flag anything likely to slip through the cracks.

### 4.4. AI careers and capability building

1. **want to be an AI builder** ([video 1](https://www.facebook.com/reel/1624447839094819))
   - **Context:** You want to be an AI builder. I am in the market every day.
   - **Suggested actions:**
     - You are going to have to sell against me.

2. **One of our builders shipped a fleet management dashboard** ([video 1](https://www.facebook.com/reel/4454122488165441))
   - **Context:** One of our builders shipped a fleet management dashboard. 130 heavy transport vehicles.
   - **Suggested actions:**
     - Route optimization.

## 5. Product, customers, and market

### 5.1. Discovery, validation, and prioritization

1. **Your mobile app sends every API call in plain text** ([video 1](https://www.facebook.com/reel/2601163750355147))
   - **Context:** Your mobile app sends every API call in plain text. Someone on the same coffee shop WiFi just watched your users log in.
   - **Suggested actions:**
     - Encrypt sensitive payloads.
     - Use secure storage.
     - Fix the transport before your users pay for it.

2. **built an AI feature into your app** ([video 1](https://www.facebook.com/reel/1748332739723178))
   - **Context:** You built an AI feature into your app. A user told your AI to ignore its instructions and show every customer record in your database.
   - **Suggested actions:**
     - Scope every connection to the current user.
     - Filter every response before it reaches anyone.
     - Make sure users can only open their own room.

3. **There are 10,000 business owners within 50 miles of you bleeding money on third-party fe…** ([video 1](https://www.facebook.com/reel/977706138700654))
   - **Context:** There are 10,000 business owners within 50 miles of you bleeding money on third-party fees. A bakery paying DoorDash 22% on every order could lease a vehicle, hire a driver, and build a custom app for less.
   - **Suggested actions:**
     - Stop building platforms nobody asked for.
     - Start solving problems people are already paying to have solved.

4. **10,000 people are working on your idea right now** ([video 1](https://www.facebook.com/reel/4386040061634039))
   - **Context:** 10,000 people are working on your idea right now. None of them are worried about you.
   - **Suggested actions:**
     - Stop building tools for your competitors.
     - Build weapons for one company.

5. **builds features** ([video 1](https://www.facebook.com/reel/1924548441835693))
   - **Context:** Your AI builds features. It has never asked you who they are for.
   - **Suggested actions:**
     - Audit their software.
     - Stop guessing what to build.

6. **Your idea is not your moat** ([video 1](https://www.facebook.com/reel/1050152864074066))
   - **Context:** Your idea is not your moat. Your ability to execute is.
   - **Suggested actions:**
     - Protect your code.

7. **picked your infrastructure** ([video 1](https://www.facebook.com/reel/1039040725380890))
   - **Context:** Your AI picked your infrastructure. It also picked your customer ceiling.
   - **Suggested actions:**
     - Document it before your next pitch.

8. **generated a feature in 20 minutes** ([video 1](https://www.facebook.com/reel/1032316562669080))
   - **Context:** Your AI generated a feature in 20 minutes. Nobody tested it.
   - **Suggested actions:**
     - Write tests alongside every feature.
     - Set a 60% coverage threshold.
     - Separate unit from integration.

9. **handles 70% of support** ([video 1](https://www.facebook.com/reel/1410728551116030))
   - **Context:** Your AI handles 70% of support. The other 30% determines whether customers stay or leave.
   - **Suggested actions:**
     - Build the 70% so you have time for the 30%.

10. **Raw AI output should never touch your users** ([video 1](https://www.facebook.com/reel/994882979803844))
   - **Context:** That's a win.🏆
   - **Suggested actions:**
     - Raw AI output should never touch your users.
     - Validate, retry with feedback, degrade gracefully.

11. **keeps building new features while your existing features are broken** ([video 1](https://www.facebook.com/reel/1072841578722719))
   - **Context:** Your AI keeps building new features while your existing features are broken. And you keep letting it because building feels like progress.
   - **Suggested actions:**
     - Stop building and start fixing.

### 5.2. User experience, onboarding, and retention

1. **got featured on Product Hunt** ([video 1](https://www.facebook.com/reel/920941273847563))
   - **Context:** Your app got featured on Product Hunt. 4,000 signups in 48 hours.
   - **Suggested actions:**
     - Time-to-value in 60 seconds, not days.
     - Progressive disclosure that gates complexity behind achievement.
     - Re-engagement triggers tied to something the user actually created.

2. **have 6,000 users and fewer of them come back every week** ([video 1](https://www.facebook.com/reel/1031086076342490))
   - **Context:** You have 6,000 users and fewer of them come back every week. Your app is dying in slow motion and your dashboard is lying to you about it.
   - **Suggested actions:**
     - Build cohort analysis, usage event tracking, and automated drop-off alerts.

3. **Your user clicked delete my account** ([video 1](https://www.facebook.com/reel/1260593892709024))
   - **Context:** Your user clicked delete my account. You deleted their data.
   - **Suggested actions:**
     - Build a retention policy engine, map your obligations, and create an audit trail before your first user asks to leave.

4. **They survived the first 48 hours** ([video 1](https://www.facebook.com/reel/1007132982100131))
   - **Context:** They survived the first 48 hours. They are leaving at week three.
   - **Suggested actions:**
     - Track activity patterns, flag the first missed session, and send re-engagement that shows what they are missing.

5. **60% of signups never return after day two** ([video 1](https://www.facebook.com/reel/1531251878481387))
   - **Context:** 60% of signups never return after day two. Not because the product is bad.
   - **Suggested actions:**
     - Track activation.
     - Measure the aha moment.
     - Flag the churn signal.

### 5.3. Positioning, distribution, and vertical products

1. **Every business within five miles of you has a scheduling problem they are paying someone…** ([video 1](https://www.facebook.com/reel/1054378134136784))
   - **Context:** Every business within five miles of you has a scheduling problem they are paying someone else to solve badly. The salon is paying $200 a month for a platform that cannot handle walk-ins.
   - **Suggested actions:**
     - Build a system for one operator.
     - Stop paying for software that was built for everyone and works for no one.

### 5.4. Build, buy, and platform decisions

1. **used one AI to build your entire app** ([video 1](https://www.facebook.com/reel/2375147073018232))
   - **Context:** You used one AI to build your entire app. You are using the same AI to check its own work.
   - **Suggested actions:**
     - Run your code through a second AI platform.
     - Rotate which platform builds and which reviews.

2. **We ran one test on a client's CRM** ([video 1](https://www.facebook.com/reel/26565296876467590))
   - **Context:** We ran one test on a client's CRM. 2.3M in duplicate records out of 10M.
   - **Suggested actions:**
     - Run it before you buy any AI tool.

3. **I get 6-12 calls a week: "We want AI but don't know where to start." My answer?** ([video 1](https://www.facebook.com/reel/1729898438170223))
   - **Context:** I get 6-12 calls a week: "We want AI but don't know where to start." My answer? You're not ready.
   - **Suggested actions:**
     - Pick any AI platform, spend 10-15 minutes a day talking to it about your business.

## 6. Business operations, strategy, and economics

### 6.1. ROI, measurement, and financial control

1. **built your Stripe checkout** ([video 1](https://www.facebook.com/reel/28724713300468157))
   - **Context:** Your AI built your Stripe checkout. The price lives in your frontend.
   - **Suggested actions:**
     - Create sessions server-side with database prices.
     - Use Stripe Price IDs.
     - Verify payment with webhooks before provisioning access.

2. **GitHub just showed you exactly where your AI money goes** ([video 1](https://www.facebook.com/reel/1079096244515787))
   - **Context:** GitHub just showed you exactly where your AI money goes. Most of you will never look.
   - **Suggested actions:**
     - Route models by task complexity.
     - Cache repeated inputs.
     - Build a weekly cost breakdown.

3. **AI Directed Engineering gets you to launch** ([video 1](https://www.facebook.com/reel/978458611883831))
   - **Context:** AI Directed Engineering gets you to launch. Conversion engineering gets you to revenue.
   - **Suggested actions:**
     - Measure it the same way you measure uptime.

4. **Nobody is measuring whether their AI build is actually making money** ([video 1](https://www.facebook.com/reel/1068477872651884))
   - **Context:** Nobody is measuring whether their AI build is actually making money. You can tell me what you pay for your subscription.
   - **Suggested actions:**
     - Build cost-per-feature tracking, per-user profitability, and a living P&L.

5. **Not every customer deserves your business** ([video 1](https://www.facebook.com/reel/1590083985812136))
   - **Context:** Not every customer deserves your business. Here is how you build the system that protects you from the next bad one.
   - **Suggested actions:**
     - The one you should have walked away from will cost you more than the ten you turned down.

6. **built a product** ([video 1](https://www.facebook.com/reel/1453156869957204))
   - **Context:** Your AI built a product. It did not register a business.
   - **Suggested actions:**
     - Research entity structures, draft your operating agreement, and build a pre-revenue checklist before you take a single dollar.

7. **2 cents per API call sounds like nothing** ([video 1](https://www.facebook.com/reel/953461890650932))
   - **Context:** 2 cents per API call sounds like nothing. Until you do the math on 1,000 users hitting it 10x a day.
   - **Suggested actions:**
     - Cache everything — same question shouldn't cost you twice.
     - Route smart — 80% of your calls don't need the expensive model.
     - Set hard spend caps — alert at 70%, kill at 90% Budget the prompt bill before you ship.

8. **74% of companies cannot measure their AI ROI** ([video 1](https://www.facebook.com/reel/2065639224277843))
   - **Context:** 74% of companies cannot measure their AI ROI. The public caption promises a fix but does not expose the reel's detailed steps.
   - **Suggested actions:**
     - Establish a measurable AI ROI process instead of treating adoption as sufficient.

### 6.2. Process automation and operating systems

1. **Your admin dashboard has no authentication** ([video 1](https://www.facebook.com/reel/1823395089530746))
   - **Context:** Your admin dashboard has no authentication. Your AI assumed only you would know the URL.
   - **Suggested actions:**
     - Add authentication to every admin route.
     - Move to a non-guessable path.
     - Log every action.

2. **Three buckets** ([video 1](https://www.facebook.com/reel/2414419955700203))
   - **Context:** Every task goes in one before I automate anything. Team hates it → automate now
   - **Suggested actions:**
     - Sort every task into one of three buckets before automating it.
     - Automate tasks the team hates.
     - Augment enjoyable tasks when volume is the problem.
     - Protect identity-critical tasks and do not automate them.

3. **We replaced their favorite meeting with a robot** ([video 1](https://www.facebook.com/reel/1330744878915842))
   - **Context:** We replaced their favorite meeting with a robot. They hated us.
   - **Suggested actions:**
     - Automate burdens.
     - Protect meaning.

### 6.3. Sales, marketing, and client management

1. **collected revenue from 12 states** ([video 1](https://www.facebook.com/reel/1581000997069129))
   - **Context:** Your AI collected revenue from 12 states. You owe sales tax in 9 of them.
   - **Suggested actions:**
     - Map your nexus exposure, enable tax collection at checkout, and build a filing calendar before a state finds you first.

2. **"I thought that was included." That sentence has ended more builder businesses than any…** ([video 1](https://www.facebook.com/reel/1714468026504828))
   - **Context:** "I thought that was included." That sentence has ended more builder businesses than any bug, any outage, or any security breach. Today I walk through three things you direct your AI to add to every proposal: an out-of-scope section, a change order process, and acceptance criteria for every deliverable.
   - **Suggested actions:**
     - Add an out-of-scope section to every proposal, covering common exclusions such as hosting, third-party API costs, content, maintenance, training, and migration.
     - Define a change-order process for requesting, estimating, pricing, and approving added scope.
     - Write measurable acceptance criteria for every deliverable.

3. **Client spent $80K on a custom dashboard** ([video 1](https://www.facebook.com/reel/1578357096988900))
   - **Context:** Client spent $80K on a custom dashboard. We replaced it with AI-pushed insights.
   - **Suggested actions:**
     - Push the insight to the person.
     - Don't make the person come to the insight.

4. **My proposals write themselves** ([video 1](https://www.facebook.com/reel/1860061527978293))
   - **Context:** My proposals write themselves. Every business owner knows this pain!
   - **Suggested actions:**
     - Record every sales call.
     - Give the recording to an AI chief of staff to extract scope, needs, budget, timeline, and risks.
     - Have the AI draft a statement of work from the actual conversation.
     - Review, edit, and send the proposal the same day.

### 6.4. Strategy, leadership, and operating model

1. **Stop calling it AI strategy** ([video 1](https://www.facebook.com/reel/1695043978346710))
   - **Context:** Nobody talks about their ‘telephone strategy' anymore. It's just how you communicate.
   - **Suggested actions:**
     - Stop calling it AI strategy.
     - Start calling it business strategy with AI.
     - Remove ‘AI' from your strategy doc.
     - Replace it with the business outcome.

## 7. Compliance and risk governance

### 7.1. Policies, regulation, and data governance

1. **A founder asked how a solo builder keeps up with compliance when the laws change faster…** ([video 1](https://www.facebook.com/reel/1106634615382636))
   - **Context:** A founder asked how a solo builder keeps up with compliance when the laws change faster than the product ships. Not a lawyer.
   - **Suggested actions:**
     - Three documents cannot wait: privacy policy, terms of service, data processing agreement.
     - Your AI can draft all three in an afternoon.
     - Set a 90-day compliance calendar.

2. **Six documents before your first paying user** ([video 1](https://www.facebook.com/reel/1578621730282880))
   - **Context:** Six documents before your first paying user. Terms of service.
   - **Suggested actions:**
     - Your AI can draft every one.

3. **Your user clicked delete my account** ([video 1](https://www.facebook.com/reel/1452261193324871))
   - **Context:** Your user clicked delete my account. Your AI built login.
   - **Suggested actions:**
     - Map the cascade, implement soft delete with a retention window, and build the GDPR response.

4. **Your checkout takes 12 seconds because your AI built the whole process as one chain** ([video 1](https://www.facebook.com/reel/1023424417217241))
   - **Context:** Your checkout takes 12 seconds because your AI built the whole process as one chain. Queue the rest.
   - **Suggested actions:**
     - Separate the response from the work.
     - Monitor the queue.
     - Stop chaining.
     - Start orchestrating.

### 7.2. Assurance, controls, and enterprise readiness

1. **built a healthcare app** ([video 1](https://www.facebook.com/reel/906806962476670))
   - **Context:** Your AI built a healthcare app. It has never heard of HIPAA.
   - **Suggested actions:**
     - Encrypt PHI, build access controls with audit logging, and execute BAAs with every third-party service.

2. **Enterprise deals require SOC** ([video 1](https://www.facebook.com/reel/1446949810450433))
   - **Context:** Enterprise deals require SOC
   - **Suggested actions:**
     - Automate the audit.
     - Ship in 60 days.
