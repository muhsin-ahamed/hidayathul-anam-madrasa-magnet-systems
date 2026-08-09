import app from './app';
import { env } from './config/env';

const port = Number(process.env.PORT || env.PORT || 5000);
const host = '0.0.0.0';

app.listen(port, host, () => {
  console.log(`Server is running on ${host}:${port}`);
});

